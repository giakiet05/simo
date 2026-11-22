package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgxpool"

	"simo-server/internal/model"
)

// SyncRepository handles transactional database persistence and delta queries for synchronization.
type SyncRepository struct {
	pool *pgxpool.Pool
}

// NewSyncRepository creates a new SyncRepository instance.
//
// @param pool *pgxpool.Pool database connection pool
// @returns *SyncRepository
func NewSyncRepository(pool *pgxpool.Pool) *SyncRepository {
	return &SyncRepository{pool: pool}
}

// ProcessSyncCycle executes the complete Push-First, Pull-Second cycle inside a single PostgreSQL transaction.
//
// @param ctx context.Context
// @param userID uuid.UUID
// @param lastSynced *model.FlexibleTime
// @param mutations *model.SyncMutations
// @returns serverTime time.Time, changes *model.SyncChanges,
// rejected []model.RejectedRecord (pushed records not applied because another user owns the ID), error
func (r *SyncRepository) ProcessSyncCycle(
	ctx context.Context,
	userID uuid.UUID,
	lastSynced *model.FlexibleTime,
	mutations *model.SyncMutations,
) (time.Time, *model.SyncChanges, []model.RejectedRecord, error) {
	tx, err := r.pool.Begin(ctx)
	if err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("failed to begin sync transaction: %w", err)
	}
	defer func() {
		// Rollback after a successful Commit is a no-op returning ErrTxClosed.
		_ = tx.Rollback(ctx)
	}()

	// Serialize sync cycles per user. Without this, two devices syncing concurrently can
	// commit rows stamped with a server_updated_at older than the cursor the other device
	// already received, and those rows would never be pulled by that device.
	if _, err := tx.Exec(ctx, `SELECT pg_advisory_xact_lock(hashtextextended($1, 0))`, userID.String()); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("failed to acquire per-user sync lock: %w", err)
	}

	// Taken after the lock (clock_timestamp, not NOW(), which is frozen at transaction start),
	// so every cycle's stamp is strictly greater than that of any previously committed cycle.
	// All rows written in this cycle carry it and it is returned as the client's next cursor.
	var syncTS time.Time
	if err := tx.QueryRow(ctx, `SELECT clock_timestamp()`).Scan(&syncTS); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("failed to read sync timestamp: %w", err)
	}
	syncTS = syncTS.UTC()

	// Ensure user exists in users table (auto-create dev user if needed)
	if _, err := tx.Exec(ctx, `
		INSERT INTO users (id, email, display_name)
		VALUES ($1, $2, $3)
		ON CONFLICT (id) DO NOTHING
	`, userID, fmt.Sprintf("user_%s@simo.app", userID.String()[:8]), "Simo User"); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("failed to ensure user record: %w", err)
	}

	// =========================================================================
	// PHASE 1: PUSH (Apply incoming mutations with Last-Write-Wins & Tombstones)
	// =========================================================================
	rejected := make([]model.RejectedRecord, 0)
	if err := r.pushWallets(ctx, tx, userID, syncTS, mutations.Wallets, &rejected); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("push wallets failed: %w", err)
	}
	if err := r.pushCategories(ctx, tx, userID, syncTS, mutations.Categories); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("push categories failed: %w", err)
	}
	if err := r.pushRecurringConfigs(ctx, tx, userID, syncTS, mutations.RecurringConfigs, &rejected); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("push recurring configs failed: %w", err)
	}
	if err := r.pushTransactions(ctx, tx, userID, syncTS, mutations.Transactions, &rejected); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("push transactions failed: %w", err)
	}
	if err := r.pushWalletTransfers(ctx, tx, userID, syncTS, mutations.WalletTransfers, &rejected); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("push wallet transfers failed: %w", err)
	}
	if err := r.pushMonthlyBudgets(ctx, tx, userID, syncTS, mutations.MonthlyBudgets); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("push monthly budgets failed: %w", err)
	}
	if err := r.pushCategoryMonthlyBudgets(ctx, tx, userID, syncTS, mutations.CategoryMonthlyBudgets); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("push category monthly budgets failed: %w", err)
	}
	if err := r.pushSavingGoals(ctx, tx, userID, syncTS, mutations.SavingGoals, &rejected); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("push saving goals failed: %w", err)
	}
	if err := r.pushSavingGoalLogs(ctx, tx, userID, syncTS, mutations.SavingGoalLogs, &rejected); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("push saving goal logs failed: %w", err)
	}
	if err := r.pushLoanContacts(ctx, tx, userID, syncTS, mutations.LoanContacts, &rejected); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("push loan contacts failed: %w", err)
	}
	if err := r.pushLoanTransactions(ctx, tx, userID, syncTS, mutations.LoanTransactions, &rejected); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("push loan transactions failed: %w", err)
	}
	if err := r.applyDeletions(ctx, tx, userID, syncTS, mutations.Deletions, &rejected); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("apply deletions failed: %w", err)
	}

	// =========================================================================
	// PHASE 2: PULL (Fetch all records with server_updated_at > lastSynced)
	// =========================================================================
	changes, err := r.pullChanges(ctx, tx, userID, lastSynced)
	if err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("pull changes failed: %w", err)
	}

	if err := tx.Commit(ctx); err != nil {
		return time.Time{}, nil, nil, fmt.Errorf("failed to commit sync transaction: %w", err)
	}

	return syncTS, changes, rejected, nil
}

// execOwnedUpsert runs an ID-keyed upsert whose UPDATE branch is guarded by user_id, and records a
// rejection when nothing was written because the existing row belongs to another user.
//
// A zero-row result has two causes: the stored copy is newer (a legitimate Last-Write-Wins skip, not
// reported) or the ID is owned by another user. Without telling them apart, a client whose IDs were
// first pushed under another account keeps receiving 200 while none of its data is ever stored.
//
// @param ctx context.Context
// @param tx pgx.Tx open sync transaction
// @param userID uuid.UUID authenticated user performing the push
// @param rejected *[]model.RejectedRecord collector for refused records
// @param table string table name (a constant from this file, never client input)
// @param id uuid.UUID primary key of the pushed record
// @param query string upsert statement
// @param args ...any upsert arguments
// @returns error when the upsert or the ownership lookup fails
func execOwnedUpsert(
	ctx context.Context,
	tx pgx.Tx,
	userID uuid.UUID,
	rejected *[]model.RejectedRecord,
	table string,
	id uuid.UUID,
	query string,
	args ...any,
) error {
	tag, err := tx.Exec(ctx, query, args...)
	if err != nil {
		return err
	}
	if tag.RowsAffected() > 0 {
		return nil
	}
	return recordIfOwnedByOtherUser(ctx, tx, userID, rejected, table, id.String())
}

// recordIfOwnedByOtherUser appends a rejection when a row with the given ID exists under another user.
//
// @param ctx context.Context
// @param tx pgx.Tx open sync transaction
// @param userID uuid.UUID authenticated user performing the push
// @param rejected *[]model.RejectedRecord collector for refused records
// @param table string allowlisted table name
// @param id string primary key of the record
// @returns error when the lookup query fails
func recordIfOwnedByOtherUser(
	ctx context.Context,
	tx pgx.Tx,
	userID uuid.UUID,
	rejected *[]model.RejectedRecord,
	table string,
	id string,
) error {
	var foreign bool
	query := fmt.Sprintf(`SELECT EXISTS (SELECT 1 FROM %s WHERE id = $1 AND user_id <> $2)`, table)
	if err := tx.QueryRow(ctx, query, id, userID).Scan(&foreign); err != nil {
		return fmt.Errorf("failed to check owner of %s %s: %w", table, id, err)
	}
	if foreign {
		*rejected = append(*rejected, model.RejectedRecord{
			Table:  table,
			ID:     id,
			Reason: model.RejectReasonOwnedByAnotherUser,
		})
	}
	return nil
}

// parentExistsForUser checks whether a parent entity with the given UUID belongs to the authenticated user.
//
// @param ctx context.Context
// @param tx pgx.Tx open sync transaction
// @param table string allowlisted parent table name
// @param id uuid.UUID primary key of the parent entity
// @param userID uuid.UUID authenticated user ID
// @returns bool true if the parent record exists for the user, error on query failure
func parentExistsForUser(
	ctx context.Context,
	tx pgx.Tx,
	table string,
	id uuid.UUID,
	userID uuid.UUID,
) (bool, error) {
	var exists bool
	query := fmt.Sprintf(`SELECT EXISTS (SELECT 1 FROM %s WHERE id = $1 AND user_id = $2)`, table)
	if err := tx.QueryRow(ctx, query, id, userID).Scan(&exists); err != nil {
		return false, fmt.Errorf("failed to check parent %s %s: %w", table, id, err)
	}
	return exists, nil
}

// pushWallets upserts client wallet mutations with Last-Write-Wins and user ownership enforcement.
func (r *SyncRepository) pushWallets(ctx context.Context, tx pgx.Tx, userID uuid.UUID, syncTS time.Time, list []model.WalletSync, rejected *[]model.RejectedRecord) error {
	query := `
		INSERT INTO wallets (
			id, user_id, name, type, initial_balance, color, icon, currency,
			is_default, exclude_from_total, priority, client_created_at, client_updated_at, server_updated_at, deleted_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $15, $14)
		ON CONFLICT (id) DO UPDATE SET
			name = EXCLUDED.name,
			type = EXCLUDED.type,
			initial_balance = EXCLUDED.initial_balance,
			color = EXCLUDED.color,
			icon = EXCLUDED.icon,
			currency = EXCLUDED.currency,
			is_default = EXCLUDED.is_default,
			exclude_from_total = EXCLUDED.exclude_from_total,
			priority = EXCLUDED.priority,
			client_updated_at = EXCLUDED.client_updated_at,
			server_updated_at = $15,
			deleted_at = COALESCE(wallets.deleted_at, EXCLUDED.deleted_at)
		WHERE EXCLUDED.client_updated_at >= wallets.client_updated_at
		  AND wallets.user_id = EXCLUDED.user_id;
	`
	for _, w := range list {
		if err := execOwnedUpsert(ctx, tx, userID, rejected, "wallets", w.ID, query,
			w.ID, userID, w.Name, w.Type, w.InitialBalance, w.Color, w.Icon, w.Currency,
			w.IsDefault, w.ExcludeFromTotal, w.Priority, w.ClientCreatedAt, w.ClientUpdatedAt, w.DeletedAt, syncTS,
		); err != nil {
			return err
		}
	}
	return nil
}

// pushCategories upserts client category mutations scoped per user.
func (r *SyncRepository) pushCategories(ctx context.Context, tx pgx.Tx, userID uuid.UUID, syncTS time.Time, list []model.CategorySync) error {
	query := `
		INSERT INTO categories (
			id, user_id, name, type, icon, color, budget_limit,
			client_created_at, client_updated_at, server_updated_at, deleted_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $11, $10)
		ON CONFLICT (user_id, id) DO UPDATE SET
			name = EXCLUDED.name,
			type = EXCLUDED.type,
			icon = EXCLUDED.icon,
			color = EXCLUDED.color,
			budget_limit = EXCLUDED.budget_limit,
			client_updated_at = EXCLUDED.client_updated_at,
			server_updated_at = $11,
			deleted_at = COALESCE(categories.deleted_at, EXCLUDED.deleted_at)
		WHERE EXCLUDED.client_updated_at >= categories.client_updated_at
		  AND categories.user_id = EXCLUDED.user_id;
	`
	for _, c := range list {
		if _, err := tx.Exec(ctx, query,
			c.ID, userID, c.Name, c.Type, c.Icon, c.Color, c.BudgetLimit,
			c.ClientCreatedAt, c.ClientUpdatedAt, c.DeletedAt, syncTS,
		); err != nil {
			return err
		}
	}
	return nil
}

// pushTransactions upserts client transaction mutations while safely nullifying dangling or cross-tenant
// wallet_id and recurring_config_id references so missing optional parents never abort the sync transaction.
func (r *SyncRepository) pushTransactions(ctx context.Context, tx pgx.Tx, userID uuid.UUID, syncTS time.Time, list []model.TransactionSync, rejected *[]model.RejectedRecord) error {
	query := `
		INSERT INTO transactions (
			id, user_id, wallet_id, category_id, recurring_config_id,
			amount, formula, note, type, transaction_date,
			client_created_at, client_updated_at, server_updated_at, deleted_at
		) VALUES (
			$1, $2,
			(SELECT id FROM wallets WHERE id = $3 AND user_id = $2),
			$4,
			(SELECT id FROM recurring_configs WHERE id = $5 AND user_id = $2),
			$6, $7, $8, $9, $10, $11, $12, $14, $13
		)
		ON CONFLICT (id) DO UPDATE SET
			wallet_id = EXCLUDED.wallet_id,
			category_id = EXCLUDED.category_id,
			recurring_config_id = EXCLUDED.recurring_config_id,
			amount = EXCLUDED.amount,
			formula = EXCLUDED.formula,
			note = EXCLUDED.note,
			type = EXCLUDED.type,
			transaction_date = EXCLUDED.transaction_date,
			client_updated_at = EXCLUDED.client_updated_at,
			server_updated_at = $14,
			deleted_at = COALESCE(transactions.deleted_at, EXCLUDED.deleted_at)
		WHERE EXCLUDED.client_updated_at >= transactions.client_updated_at
		  AND transactions.user_id = EXCLUDED.user_id;
	`
	for _, t := range list {
		if err := execOwnedUpsert(ctx, tx, userID, rejected, "transactions", t.ID, query,
			t.ID, userID, t.WalletID, t.CategoryID, t.RecurringConfigID,
			t.Amount, t.Formula, t.Note, t.Type, t.TransactionDate,
			t.ClientCreatedAt, t.ClientUpdatedAt, t.DeletedAt, syncTS,
		); err != nil {
			return err
		}
	}
	return nil
}

// pushWalletTransfers upserts client wallet transfer mutations, rejecting transfers whose source or destination
// wallet does not exist for the authenticated user instead of failing with a foreign key constraint error.
func (r *SyncRepository) pushWalletTransfers(ctx context.Context, tx pgx.Tx, userID uuid.UUID, syncTS time.Time, list []model.WalletTransferSync, rejected *[]model.RejectedRecord) error {
	query := `
		INSERT INTO wallet_transfers (
			id, user_id, source_wallet_id, destination_wallet_id, amount, fee, transfer_date, note,
			client_created_at, client_updated_at, server_updated_at, deleted_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $12, $11)
		ON CONFLICT (id) DO UPDATE SET
			source_wallet_id = EXCLUDED.source_wallet_id,
			destination_wallet_id = EXCLUDED.destination_wallet_id,
			amount = EXCLUDED.amount,
			fee = EXCLUDED.fee,
			transfer_date = EXCLUDED.transfer_date,
			note = EXCLUDED.note,
			client_updated_at = EXCLUDED.client_updated_at,
			server_updated_at = $12,
			deleted_at = COALESCE(wallet_transfers.deleted_at, EXCLUDED.deleted_at)
		WHERE EXCLUDED.client_updated_at >= wallet_transfers.client_updated_at
		  AND wallet_transfers.user_id = EXCLUDED.user_id;
	`
	for _, wt := range list {
		srcOK, err := parentExistsForUser(ctx, tx, "wallets", wt.SourceWalletID, userID)
		if err != nil {
			return err
		}
		dstOK, err := parentExistsForUser(ctx, tx, "wallets", wt.DestinationWalletID, userID)
		if err != nil {
			return err
		}
		if !srcOK || !dstOK {
			*rejected = append(*rejected, model.RejectedRecord{
				Table:  "wallet_transfers",
				ID:     wt.ID.String(),
				Reason: model.RejectReasonMissingParent,
			})
			continue
		}
		if err := execOwnedUpsert(ctx, tx, userID, rejected, "wallet_transfers", wt.ID, query,
			wt.ID, userID, wt.SourceWalletID, wt.DestinationWalletID, wt.Amount, wt.Fee, wt.TransferDate, wt.Note,
			wt.ClientCreatedAt, wt.ClientUpdatedAt, wt.DeletedAt, syncTS,
		); err != nil {
			return err
		}
	}
	return nil
}

// pushMonthlyBudgets upserts client monthly budget mutations scoped per user, year, and month.
func (r *SyncRepository) pushMonthlyBudgets(ctx context.Context, tx pgx.Tx, userID uuid.UUID, syncTS time.Time, list []model.MonthlyBudgetSync) error {
	query := `
		INSERT INTO monthly_budgets (
			id, user_id, year, month, amount,
			client_created_at, client_updated_at, server_updated_at, deleted_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $9, $8)
		ON CONFLICT (user_id, year, month) DO UPDATE SET
			amount = EXCLUDED.amount,
			client_updated_at = EXCLUDED.client_updated_at,
			server_updated_at = $9,
			deleted_at = COALESCE(monthly_budgets.deleted_at, EXCLUDED.deleted_at)
		WHERE EXCLUDED.client_updated_at >= monthly_budgets.client_updated_at
		  AND monthly_budgets.user_id = EXCLUDED.user_id;
	`
	for _, mb := range list {
		if _, err := tx.Exec(ctx, query,
			mb.ID, userID, mb.Year, mb.Month, mb.Amount,
			mb.ClientCreatedAt, mb.ClientUpdatedAt, mb.DeletedAt, syncTS,
		); err != nil {
			return err
		}
	}
	return nil
}

// pushCategoryMonthlyBudgets upserts client category-specific monthly budget mutations.
func (r *SyncRepository) pushCategoryMonthlyBudgets(ctx context.Context, tx pgx.Tx, userID uuid.UUID, syncTS time.Time, list []model.CategoryMonthlyBudgetSync) error {
	query := `
		INSERT INTO category_monthly_budgets (
			id, user_id, category_id, year, month, amount,
			client_created_at, client_updated_at, server_updated_at, deleted_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $10, $9)
		ON CONFLICT (user_id, category_id, year, month) DO UPDATE SET
			amount = EXCLUDED.amount,
			client_updated_at = EXCLUDED.client_updated_at,
			server_updated_at = $10,
			deleted_at = COALESCE(category_monthly_budgets.deleted_at, EXCLUDED.deleted_at)
		WHERE EXCLUDED.client_updated_at >= category_monthly_budgets.client_updated_at
		  AND category_monthly_budgets.user_id = EXCLUDED.user_id;
	`
	for _, cmb := range list {
		if _, err := tx.Exec(ctx, query,
			cmb.ID, userID, cmb.CategoryID, cmb.Year, cmb.Month, cmb.Amount,
			cmb.ClientCreatedAt, cmb.ClientUpdatedAt, cmb.DeletedAt, syncTS,
		); err != nil {
			return err
		}
	}
	return nil
}

// pushSavingGoals upserts client saving goal mutations.
func (r *SyncRepository) pushSavingGoals(ctx context.Context, tx pgx.Tx, userID uuid.UUID, syncTS time.Time, list []model.SavingGoalSync, rejected *[]model.RejectedRecord) error {
	query := `
		INSERT INTO saving_goals (
			id, user_id, name, target_amount, current_amount, target_date, color, icon, note, status,
			client_created_at, client_updated_at, server_updated_at, deleted_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $14, $13)
		ON CONFLICT (id) DO UPDATE SET
			name = EXCLUDED.name,
			target_amount = EXCLUDED.target_amount,
			current_amount = EXCLUDED.current_amount,
			target_date = EXCLUDED.target_date,
			color = EXCLUDED.color,
			icon = EXCLUDED.icon,
			note = EXCLUDED.note,
			status = EXCLUDED.status,
			client_updated_at = EXCLUDED.client_updated_at,
			server_updated_at = $14,
			deleted_at = COALESCE(saving_goals.deleted_at, EXCLUDED.deleted_at)
		WHERE EXCLUDED.client_updated_at >= saving_goals.client_updated_at
		  AND saving_goals.user_id = EXCLUDED.user_id;
	`
	for _, sg := range list {
		if err := execOwnedUpsert(ctx, tx, userID, rejected, "saving_goals", sg.ID, query,
			sg.ID, userID, sg.Name, sg.TargetAmount, sg.CurrentAmount, sg.TargetDate, sg.Color, sg.Icon, sg.Note, sg.Status,
			sg.ClientCreatedAt, sg.ClientUpdatedAt, sg.DeletedAt, syncTS,
		); err != nil {
			return err
		}
	}
	return nil
}

// pushSavingGoalLogs upserts client saving goal log mutations, rejecting logs whose parent saving goal
// does not exist for the authenticated user instead of failing with a foreign key constraint error.
func (r *SyncRepository) pushSavingGoalLogs(ctx context.Context, tx pgx.Tx, userID uuid.UUID, syncTS time.Time, list []model.SavingGoalLogSync, rejected *[]model.RejectedRecord) error {
	query := `
		INSERT INTO saving_goal_logs (
			id, user_id, goal_id, amount, type, log_date, note,
			client_created_at, client_updated_at, server_updated_at, deleted_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $11, $10)
		ON CONFLICT (id) DO UPDATE SET
			amount = EXCLUDED.amount,
			type = EXCLUDED.type,
			log_date = EXCLUDED.log_date,
			note = EXCLUDED.note,
			client_updated_at = EXCLUDED.client_updated_at,
			server_updated_at = $11,
			deleted_at = COALESCE(saving_goal_logs.deleted_at, EXCLUDED.deleted_at)
		WHERE EXCLUDED.client_updated_at >= saving_goal_logs.client_updated_at
		  AND saving_goal_logs.user_id = EXCLUDED.user_id;
	`
	for _, sgl := range list {
		goalOK, err := parentExistsForUser(ctx, tx, "saving_goals", sgl.GoalID, userID)
		if err != nil {
			return err
		}
		if !goalOK {
			*rejected = append(*rejected, model.RejectedRecord{
				Table:  "saving_goal_logs",
				ID:     sgl.ID.String(),
				Reason: model.RejectReasonMissingParent,
			})
			continue
		}
		if err := execOwnedUpsert(ctx, tx, userID, rejected, "saving_goal_logs", sgl.ID, query,
			sgl.ID, userID, sgl.GoalID, sgl.Amount, sgl.Type, sgl.LogDate, sgl.Note,
			sgl.ClientCreatedAt, sgl.ClientUpdatedAt, sgl.DeletedAt, syncTS,
		); err != nil {
			return err
		}
	}
	return nil
}

// pushLoanContacts upserts client loan contact mutations.
func (r *SyncRepository) pushLoanContacts(ctx context.Context, tx pgx.Tx, userID uuid.UUID, syncTS time.Time, list []model.LoanContactSync, rejected *[]model.RejectedRecord) error {
	query := `
		INSERT INTO loan_contacts (
			id, user_id, contact_name, type, total_amount, remaining_amount, status,
			client_created_at, client_updated_at, server_updated_at, deleted_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $11, $10)
		ON CONFLICT (id) DO UPDATE SET
			contact_name = EXCLUDED.contact_name,
			type = EXCLUDED.type,
			total_amount = EXCLUDED.total_amount,
			remaining_amount = EXCLUDED.remaining_amount,
			status = EXCLUDED.status,
			client_updated_at = EXCLUDED.client_updated_at,
			server_updated_at = $11,
			deleted_at = COALESCE(loan_contacts.deleted_at, EXCLUDED.deleted_at)
		WHERE EXCLUDED.client_updated_at >= loan_contacts.client_updated_at
		  AND loan_contacts.user_id = EXCLUDED.user_id;
	`
	for _, lc := range list {
		if err := execOwnedUpsert(ctx, tx, userID, rejected, "loan_contacts", lc.ID, query,
			lc.ID, userID, lc.ContactName, lc.Type, lc.TotalAmount, lc.RemainingAmount, lc.Status,
			lc.ClientCreatedAt, lc.ClientUpdatedAt, lc.DeletedAt, syncTS,
		); err != nil {
			return err
		}
	}
	return nil
}

// pushLoanTransactions upserts client loan transaction mutations, rejecting transactions whose parent loan contact
// does not exist for the authenticated user instead of failing with a foreign key constraint error.
func (r *SyncRepository) pushLoanTransactions(ctx context.Context, tx pgx.Tx, userID uuid.UUID, syncTS time.Time, list []model.LoanTransactionSync, rejected *[]model.RejectedRecord) error {
	query := `
		INSERT INTO loan_transactions (
			id, user_id, loan_id, amount, type, date, due_date, note,
			client_created_at, client_updated_at, server_updated_at, deleted_at
		) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $12, $11)
		ON CONFLICT (id) DO UPDATE SET
			amount = EXCLUDED.amount,
			type = EXCLUDED.type,
			date = EXCLUDED.date,
			due_date = EXCLUDED.due_date,
			note = EXCLUDED.note,
			client_updated_at = EXCLUDED.client_updated_at,
			server_updated_at = $12,
			deleted_at = COALESCE(loan_transactions.deleted_at, EXCLUDED.deleted_at)
		WHERE EXCLUDED.client_updated_at >= loan_transactions.client_updated_at
		  AND loan_transactions.user_id = EXCLUDED.user_id;
	`
	for _, lt := range list {
		loanOK, err := parentExistsForUser(ctx, tx, "loan_contacts", lt.LoanID, userID)
		if err != nil {
			return err
		}
		if !loanOK {
			*rejected = append(*rejected, model.RejectedRecord{
				Table:  "loan_transactions",
				ID:     lt.ID.String(),
				Reason: model.RejectReasonMissingParent,
			})
			continue
		}
		if err := execOwnedUpsert(ctx, tx, userID, rejected, "loan_transactions", lt.ID, query,
			lt.ID, userID, lt.LoanID, lt.Amount, lt.Type, lt.Date, lt.DueDate, lt.Note,
			lt.ClientCreatedAt, lt.ClientUpdatedAt, lt.DeletedAt, syncTS,
		); err != nil {
			return err
		}
	}
	return nil
}

// pushRecurringConfigs upserts client recurring configuration mutations while safely nullifying dangling or
// cross-tenant wallet_id references so missing optional wallets never abort the sync transaction.
func (r *SyncRepository) pushRecurringConfigs(ctx context.Context, tx pgx.Tx, userID uuid.UUID, syncTS time.Time, list []model.RecurringConfigSync, rejected *[]model.RejectedRecord) error {
	query := `
		INSERT INTO recurring_configs (
			id, user_id, category_id, wallet_id, name, amount, type, frequency, interval,
			day_of_week, day_of_month, next_run, is_active,
			client_created_at, client_updated_at, server_updated_at, deleted_at
		) VALUES (
			$1, $2, $3,
			(SELECT id FROM wallets WHERE id = $4 AND user_id = $2),
			$5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $17, $16
		)
		ON CONFLICT (id) DO UPDATE SET
			category_id = EXCLUDED.category_id,
			wallet_id = EXCLUDED.wallet_id,
			name = EXCLUDED.name,
			amount = EXCLUDED.amount,
			type = EXCLUDED.type,
			frequency = EXCLUDED.frequency,
			interval = EXCLUDED.interval,
			day_of_week = EXCLUDED.day_of_week,
			day_of_month = EXCLUDED.day_of_month,
			next_run = EXCLUDED.next_run,
			is_active = EXCLUDED.is_active,
			client_updated_at = EXCLUDED.client_updated_at,
			server_updated_at = $17,
			deleted_at = COALESCE(recurring_configs.deleted_at, EXCLUDED.deleted_at)
		WHERE EXCLUDED.client_updated_at >= recurring_configs.client_updated_at
		  AND recurring_configs.user_id = EXCLUDED.user_id;
	`
	for _, rc := range list {
		if err := execOwnedUpsert(ctx, tx, userID, rejected, "recurring_configs", rc.ID, query,
			rc.ID, userID, rc.CategoryID, rc.WalletID, rc.Name, rc.Amount, rc.Type, rc.Frequency, rc.Interval,
			rc.DayOfWeek, rc.DayOfMonth, rc.NextRun, rc.IsActive,
			rc.ClientCreatedAt, rc.ClientUpdatedAt, rc.DeletedAt, syncTS,
		); err != nil {
			return err
		}
	}
	return nil
}

func (r *SyncRepository) applyDeletions(ctx context.Context, tx pgx.Tx, userID uuid.UUID, syncTS time.Time, deletions []model.TombstoneDeletion, rejected *[]model.RejectedRecord) error {
	allowedTables := map[string]bool{
		"wallets":                  true,
		"wallet_transfers":         true,
		"categories":               true,
		"transactions":             true,
		"monthly_budgets":          true,
		"category_monthly_budgets": true,
		"saving_goals":             true,
		"saving_goal_logs":         true,
		"loan_contacts":            true,
		"loan_transactions":        true,
		"recurring_configs":        true,
	}

	for _, d := range deletions {
		if !allowedTables[d.TableName] {
			continue
		}
		query := fmt.Sprintf(`
			UPDATE %s SET 
				deleted_at = $1, 
				server_updated_at = $4
			WHERE user_id = $2 AND id = $3 AND (deleted_at IS NULL OR deleted_at < $1);
		`, d.TableName)

		tag, err := tx.Exec(ctx, query, d.DeletedAt, userID, d.ID, syncTS)
		if err != nil {
			return err
		}
		// Category IDs are scoped per user (primary key is user_id + id), so another user holding the
		// same ID is not a conflict and must not be reported.
		if tag.RowsAffected() == 0 && d.TableName != "categories" {
			if err := recordIfOwnedByOtherUser(ctx, tx, userID, rejected, d.TableName, d.ID); err != nil {
				return err
			}
		}
	}
	return nil
}

func (r *SyncRepository) pullChanges(ctx context.Context, tx pgx.Tx, userID uuid.UUID, lastSynced *model.FlexibleTime) (*model.SyncChanges, error) {
	changes := &model.SyncChanges{
		Wallets:                make([]model.WalletSync, 0),
		WalletTransfers:        make([]model.WalletTransferSync, 0),
		Categories:             make([]model.CategorySync, 0),
		Transactions:           make([]model.TransactionSync, 0),
		MonthlyBudgets:         make([]model.MonthlyBudgetSync, 0),
		CategoryMonthlyBudgets: make([]model.CategoryMonthlyBudgetSync, 0),
		SavingGoals:            make([]model.SavingGoalSync, 0),
		SavingGoalLogs:         make([]model.SavingGoalLogSync, 0),
		LoanContacts:           make([]model.LoanContactSync, 0),
		LoanTransactions:       make([]model.LoanTransactionSync, 0),
		RecurringConfigs:       make([]model.RecurringConfigSync, 0),
		Deletions:              make([]model.TombstoneDeletion, 0),
	}

	since := time.Time{}
	if lastSynced != nil {
		since = lastSynced.Time
	}

	// 1. Wallets
	wRows, err := tx.Query(ctx, `
		SELECT id, name, type, initial_balance, color, icon, currency, is_default, exclude_from_total, priority,
		       client_created_at, client_updated_at, server_updated_at, deleted_at
		FROM wallets WHERE user_id = $1 AND server_updated_at > $2;
	`, userID, since)
	if err != nil {
		return nil, err
	}
	defer wRows.Close()
	for wRows.Next() {
		var w model.WalletSync
		if err := wRows.Scan(&w.ID, &w.Name, &w.Type, &w.InitialBalance, &w.Color, &w.Icon, &w.Currency,
			&w.IsDefault, &w.ExcludeFromTotal, &w.Priority, &w.ClientCreatedAt, &w.ClientUpdatedAt, &w.ServerUpdatedAt, &w.DeletedAt); err != nil {
			return nil, err
		}
		if w.DeletedAt != nil {
			changes.Deletions = append(changes.Deletions, model.TombstoneDeletion{TableName: "wallets", ID: w.ID.String(), DeletedAt: *w.DeletedAt})
		} else {
			changes.Wallets = append(changes.Wallets, w)
		}
	}
	if err := wRows.Err(); err != nil {
		return nil, err
	}

	// 2. Categories
	cRows, err := tx.Query(ctx, `
		SELECT id, name, type, icon, color, budget_limit, client_created_at, client_updated_at, server_updated_at, deleted_at
		FROM categories WHERE user_id = $1 AND server_updated_at > $2;
	`, userID, since)
	if err != nil {
		return nil, err
	}
	defer cRows.Close()
	for cRows.Next() {
		var c model.CategorySync
		if err := cRows.Scan(&c.ID, &c.Name, &c.Type, &c.Icon, &c.Color, &c.BudgetLimit,
			&c.ClientCreatedAt, &c.ClientUpdatedAt, &c.ServerUpdatedAt, &c.DeletedAt); err != nil {
			return nil, err
		}
		if c.DeletedAt != nil {
			changes.Deletions = append(changes.Deletions, model.TombstoneDeletion{TableName: "categories", ID: c.ID, DeletedAt: *c.DeletedAt})
		} else {
			changes.Categories = append(changes.Categories, c)
		}
	}
	if err := cRows.Err(); err != nil {
		return nil, err
	}

	// 3. Transactions
	tRows, err := tx.Query(ctx, `
		SELECT id, wallet_id, category_id, recurring_config_id, amount, formula, note, type, transaction_date,
		       client_created_at, client_updated_at, server_updated_at, deleted_at
		FROM transactions WHERE user_id = $1 AND server_updated_at > $2;
	`, userID, since)
	if err != nil {
		return nil, err
	}
	defer tRows.Close()
	for tRows.Next() {
		var t model.TransactionSync
		var tDate time.Time
		if err := tRows.Scan(&t.ID, &t.WalletID, &t.CategoryID, &t.RecurringConfigID, &t.Amount, &t.Formula, &t.Note,
			&t.Type, &tDate, &t.ClientCreatedAt, &t.ClientUpdatedAt, &t.ServerUpdatedAt, &t.DeletedAt); err != nil {
			return nil, err
		}
		t.TransactionDate = tDate.Format("2006-01-02")
		if t.DeletedAt != nil {
			changes.Deletions = append(changes.Deletions, model.TombstoneDeletion{TableName: "transactions", ID: t.ID.String(), DeletedAt: *t.DeletedAt})
		} else {
			changes.Transactions = append(changes.Transactions, t)
		}
	}
	if err := tRows.Err(); err != nil {
		return nil, err
	}

	// 4. Wallet Transfers
	wtRows, err := tx.Query(ctx, `
		SELECT id, source_wallet_id, destination_wallet_id, amount, fee, transfer_date, note,
		       client_created_at, client_updated_at, server_updated_at, deleted_at
		FROM wallet_transfers WHERE user_id = $1 AND server_updated_at > $2;
	`, userID, since)
	if err != nil {
		return nil, err
	}
	defer wtRows.Close()
	for wtRows.Next() {
		var wt model.WalletTransferSync
		if err := wtRows.Scan(&wt.ID, &wt.SourceWalletID, &wt.DestinationWalletID, &wt.Amount, &wt.Fee, &wt.TransferDate, &wt.Note,
			&wt.ClientCreatedAt, &wt.ClientUpdatedAt, &wt.ServerUpdatedAt, &wt.DeletedAt); err != nil {
			return nil, err
		}
		if wt.DeletedAt != nil {
			changes.Deletions = append(changes.Deletions, model.TombstoneDeletion{TableName: "wallet_transfers", ID: wt.ID.String(), DeletedAt: *wt.DeletedAt})
		} else {
			changes.WalletTransfers = append(changes.WalletTransfers, wt)
		}
	}
	if err := wtRows.Err(); err != nil {
		return nil, err
	}

	// 5. Monthly Budgets
	mbRows, err := tx.Query(ctx, `
		SELECT id, year, month, amount, client_created_at, client_updated_at, server_updated_at, deleted_at
		FROM monthly_budgets WHERE user_id = $1 AND server_updated_at > $2;
	`, userID, since)
	if err != nil {
		return nil, err
	}
	defer mbRows.Close()
	for mbRows.Next() {
		var mb model.MonthlyBudgetSync
		if err := mbRows.Scan(&mb.ID, &mb.Year, &mb.Month, &mb.Amount, &mb.ClientCreatedAt, &mb.ClientUpdatedAt, &mb.ServerUpdatedAt, &mb.DeletedAt); err != nil {
			return nil, err
		}
		if mb.DeletedAt != nil {
			changes.Deletions = append(changes.Deletions, model.TombstoneDeletion{TableName: "monthly_budgets", ID: mb.ID.String(), DeletedAt: *mb.DeletedAt})
		} else {
			changes.MonthlyBudgets = append(changes.MonthlyBudgets, mb)
		}
	}
	if err := mbRows.Err(); err != nil {
		return nil, err
	}

	// 6. Category Monthly Budgets
	cmbRows, err := tx.Query(ctx, `
		SELECT id, category_id, year, month, amount, client_created_at, client_updated_at, server_updated_at, deleted_at
		FROM category_monthly_budgets WHERE user_id = $1 AND server_updated_at > $2;
	`, userID, since)
	if err != nil {
		return nil, err
	}
	defer cmbRows.Close()
	for cmbRows.Next() {
		var cmb model.CategoryMonthlyBudgetSync
		if err := cmbRows.Scan(&cmb.ID, &cmb.CategoryID, &cmb.Year, &cmb.Month, &cmb.Amount, &cmb.ClientCreatedAt, &cmb.ClientUpdatedAt, &cmb.ServerUpdatedAt, &cmb.DeletedAt); err != nil {
			return nil, err
		}
		if cmb.DeletedAt != nil {
			changes.Deletions = append(changes.Deletions, model.TombstoneDeletion{TableName: "category_monthly_budgets", ID: cmb.ID.String(), DeletedAt: *cmb.DeletedAt})
		} else {
			changes.CategoryMonthlyBudgets = append(changes.CategoryMonthlyBudgets, cmb)
		}
	}
	if err := cmbRows.Err(); err != nil {
		return nil, err
	}

	// 7. Saving Goals
	sgRows, err := tx.Query(ctx, `
		SELECT id, name, target_amount, current_amount, target_date, color, icon, note, status,
		       client_created_at, client_updated_at, server_updated_at, deleted_at
		FROM saving_goals WHERE user_id = $1 AND server_updated_at > $2;
	`, userID, since)
	if err != nil {
		return nil, err
	}
	defer sgRows.Close()
	for sgRows.Next() {
		var sg model.SavingGoalSync
		var tDate *time.Time
		if err := sgRows.Scan(&sg.ID, &sg.Name, &sg.TargetAmount, &sg.CurrentAmount, &tDate, &sg.Color, &sg.Icon, &sg.Note,
			&sg.Status, &sg.ClientCreatedAt, &sg.ClientUpdatedAt, &sg.ServerUpdatedAt, &sg.DeletedAt); err != nil {
			return nil, err
		}
		if tDate != nil {
			dStr := tDate.Format("2006-01-02")
			sg.TargetDate = &dStr
		}
		if sg.DeletedAt != nil {
			changes.Deletions = append(changes.Deletions, model.TombstoneDeletion{TableName: "saving_goals", ID: sg.ID.String(), DeletedAt: *sg.DeletedAt})
		} else {
			changes.SavingGoals = append(changes.SavingGoals, sg)
		}
	}
	if err := sgRows.Err(); err != nil {
		return nil, err
	}

	// 8. Saving Goal Logs
	sglRows, err := tx.Query(ctx, `
		SELECT id, goal_id, amount, type, log_date, note, client_created_at, client_updated_at, server_updated_at, deleted_at
		FROM saving_goal_logs WHERE user_id = $1 AND server_updated_at > $2;
	`, userID, since)
	if err != nil {
		return nil, err
	}
	defer sglRows.Close()
	for sglRows.Next() {
		var sgl model.SavingGoalLogSync
		if err := sglRows.Scan(&sgl.ID, &sgl.GoalID, &sgl.Amount, &sgl.Type, &sgl.LogDate, &sgl.Note,
			&sgl.ClientCreatedAt, &sgl.ClientUpdatedAt, &sgl.ServerUpdatedAt, &sgl.DeletedAt); err != nil {
			return nil, err
		}
		if sgl.DeletedAt != nil {
			changes.Deletions = append(changes.Deletions, model.TombstoneDeletion{TableName: "saving_goal_logs", ID: sgl.ID.String(), DeletedAt: *sgl.DeletedAt})
		} else {
			changes.SavingGoalLogs = append(changes.SavingGoalLogs, sgl)
		}
	}
	if err := sglRows.Err(); err != nil {
		return nil, err
	}

	// 9. Loan Contacts
	lcRows, err := tx.Query(ctx, `
		SELECT id, contact_name, type, total_amount, remaining_amount, status,
		       client_created_at, client_updated_at, server_updated_at, deleted_at
		FROM loan_contacts WHERE user_id = $1 AND server_updated_at > $2;
	`, userID, since)
	if err != nil {
		return nil, err
	}
	defer lcRows.Close()
	for lcRows.Next() {
		var lc model.LoanContactSync
		if err := lcRows.Scan(&lc.ID, &lc.ContactName, &lc.Type, &lc.TotalAmount, &lc.RemainingAmount, &lc.Status,
			&lc.ClientCreatedAt, &lc.ClientUpdatedAt, &lc.ServerUpdatedAt, &lc.DeletedAt); err != nil {
			return nil, err
		}
		if lc.DeletedAt != nil {
			changes.Deletions = append(changes.Deletions, model.TombstoneDeletion{TableName: "loan_contacts", ID: lc.ID.String(), DeletedAt: *lc.DeletedAt})
		} else {
			changes.LoanContacts = append(changes.LoanContacts, lc)
		}
	}
	if err := lcRows.Err(); err != nil {
		return nil, err
	}

	// 10. Loan Transactions
	ltRows, err := tx.Query(ctx, `
		SELECT id, loan_id, amount, type, date, due_date, note,
		       client_created_at, client_updated_at, server_updated_at, deleted_at
		FROM loan_transactions WHERE user_id = $1 AND server_updated_at > $2;
	`, userID, since)
	if err != nil {
		return nil, err
	}
	defer ltRows.Close()
	for ltRows.Next() {
		var lt model.LoanTransactionSync
		var dDate *time.Time
		if err := ltRows.Scan(&lt.ID, &lt.LoanID, &lt.Amount, &lt.Type, &lt.Date, &dDate, &lt.Note,
			&lt.ClientCreatedAt, &lt.ClientUpdatedAt, &lt.ServerUpdatedAt, &lt.DeletedAt); err != nil {
			return nil, err
		}
		if dDate != nil {
			dStr := dDate.Format("2006-01-02")
			lt.DueDate = &dStr
		}
		if lt.DeletedAt != nil {
			changes.Deletions = append(changes.Deletions, model.TombstoneDeletion{TableName: "loan_transactions", ID: lt.ID.String(), DeletedAt: *lt.DeletedAt})
		} else {
			changes.LoanTransactions = append(changes.LoanTransactions, lt)
		}
	}
	if err := ltRows.Err(); err != nil {
		return nil, err
	}

	// 11. Recurring Configs
	rcRows, err := tx.Query(ctx, `
		SELECT id, category_id, wallet_id, name, amount, type, frequency, interval, day_of_week, day_of_month, next_run, is_active,
		       client_created_at, client_updated_at, server_updated_at, deleted_at
		FROM recurring_configs WHERE user_id = $1 AND server_updated_at > $2;
	`, userID, since)
	if err != nil {
		return nil, err
	}
	defer rcRows.Close()
	for rcRows.Next() {
		var rc model.RecurringConfigSync
		if err := rcRows.Scan(&rc.ID, &rc.CategoryID, &rc.WalletID, &rc.Name, &rc.Amount, &rc.Type, &rc.Frequency,
			&rc.Interval, &rc.DayOfWeek, &rc.DayOfMonth, &rc.NextRun, &rc.IsActive,
			&rc.ClientCreatedAt, &rc.ClientUpdatedAt, &rc.ServerUpdatedAt, &rc.DeletedAt); err != nil {
			return nil, err
		}
		if rc.DeletedAt != nil {
			changes.Deletions = append(changes.Deletions, model.TombstoneDeletion{TableName: "recurring_configs", ID: rc.ID.String(), DeletedAt: *rc.DeletedAt})
		} else {
			changes.RecurringConfigs = append(changes.RecurringConfigs, rc)
		}
	}
	if err := rcRows.Err(); err != nil {
		return nil, err
	}

	return changes, nil
}
