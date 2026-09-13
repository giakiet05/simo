package repository

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"simo-server/internal/model"
)

// TransactionRepository handles query and manipulation of transactions for Web REST endpoints.
type TransactionRepository struct {
	pool *pgxpool.Pool
}

// NewTransactionRepository creates a new TransactionRepository.
//
// @param pool *pgxpool.Pool
// @returns *TransactionRepository
func NewTransactionRepository(pool *pgxpool.Pool) *TransactionRepository {
	return &TransactionRepository{pool: pool}
}

// TransactionFilter defines filtering criteria for querying transactions on Web.
type TransactionFilter struct {
	Page       int
	Limit      int
	WalletID   *uuid.UUID
	CategoryID *string
	Type       *string
	StartDate  *string
	EndDate    *string
	Keyword    *string
}

// ListTransactions queries paginated transactions matching filter criteria.
//
// @param ctx context.Context
// @param userID uuid.UUID
// @param filter TransactionFilter
// @returns []model.TransactionSync, totalCount int, error
func (r *TransactionRepository) ListTransactions(ctx context.Context, userID uuid.UUID, filter TransactionFilter) ([]model.TransactionSync, int, error) {
	if filter.Limit <= 0 {
		filter.Limit = 20
	}
	if filter.Page <= 0 {
		filter.Page = 1
	}
	offset := (filter.Page - 1) * filter.Limit

	query := `
		SELECT id, wallet_id, category_id, recurring_config_id, amount, formula, note, type, transaction_date,
		       client_created_at, client_updated_at, server_updated_at, deleted_at,
		       COUNT(*) OVER() as total_count
		FROM transactions
		WHERE user_id = $1 AND deleted_at IS NULL
	`
	args := []any{userID}
	argIdx := 2

	if filter.WalletID != nil {
		query += fmt.Sprintf(" AND wallet_id = $%d", argIdx)
		args = append(args, *filter.WalletID)
		argIdx++
	}
	if filter.CategoryID != nil && *filter.CategoryID != "" {
		query += fmt.Sprintf(" AND category_id = $%d", argIdx)
		args = append(args, *filter.CategoryID)
		argIdx++
	}
	if filter.Type != nil && *filter.Type != "" {
		query += fmt.Sprintf(" AND type = $%d", argIdx)
		args = append(args, *filter.Type)
		argIdx++
	}
	if filter.StartDate != nil && *filter.StartDate != "" {
		query += fmt.Sprintf(" AND transaction_date >= $%d", argIdx)
		args = append(args, *filter.StartDate)
		argIdx++
	}
	if filter.EndDate != nil && *filter.EndDate != "" {
		query += fmt.Sprintf(" AND transaction_date <= $%d", argIdx)
		args = append(args, *filter.EndDate)
		argIdx++
	}
	if filter.Keyword != nil && *filter.Keyword != "" {
		query += fmt.Sprintf(" AND note ILIKE $%d", argIdx)
		args = append(args, "%"+*filter.Keyword+"%")
		argIdx++
	}

	query += fmt.Sprintf(" ORDER BY transaction_date DESC, client_created_at DESC LIMIT $%d OFFSET $%d", argIdx, argIdx+1)
	args = append(args, filter.Limit, offset)

	rows, err := r.pool.Query(ctx, query, args...)
	if err != nil {
		return nil, 0, err
	}
	defer rows.Close()

	list := make([]model.TransactionSync, 0)
	total := 0

	for rows.Next() {
		var t model.TransactionSync
		var tDate time.Time
		if err := rows.Scan(
			&t.ID, &t.WalletID, &t.CategoryID, &t.RecurringConfigID, &t.Amount, &t.Formula, &t.Note,
			&t.Type, &tDate, &t.ClientCreatedAt, &t.ClientUpdatedAt, &t.ServerUpdatedAt, &t.DeletedAt,
			&total,
		); err != nil {
			return nil, 0, err
		}
		t.TransactionDate = tDate.Format("2006-01-02")
		list = append(list, t)
	}

	return list, total, nil
}
