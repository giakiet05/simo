package test

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"simo-server/internal/config"
	"simo-server/internal/handler"
	"simo-server/internal/model"
	"simo-server/internal/repository"
	"simo-server/internal/router"
	"simo-server/internal/service"
)

// syncEnv bundles a router wired against a real database plus a token issuer for test users.
type syncEnv struct {
	router http.Handler
	pool   *pgxpool.Pool
	auth   *service.AuthService
}

// newSyncEnv connects to DATABASE_URL and wires sync and wallet endpoints; it skips the test when no DB is configured.
func newSyncEnv(t *testing.T) *syncEnv {
	t.Helper()
	cfg := config.Load()
	if cfg.DatabaseURL == "" {
		t.Skip("Skipping integration test: DATABASE_URL not configured")
	}
	cfg.JWTSecret = "integration_test_secret_0123456789abcdef"
	pool, err := repository.InitDB(cfg.DatabaseURL)
	if err != nil {
		t.Skipf("Skipping integration test: database connection failed: %v", err)
	}
	t.Cleanup(pool.Close)

	r := router.SetupRouter(cfg, &router.Handlers{
		SyncHandler:   handler.NewSyncHandler(service.NewSyncService(repository.NewSyncRepository(pool), nil)),
		WalletHandler: handler.NewWalletHandler(repository.NewWalletRepository(pool)),
	})
	return &syncEnv{router: r, pool: pool, auth: service.NewAuthService(cfg, nil)}
}

// newUserToken issues a JWT for a fresh random user ID.
func (e *syncEnv) newUserToken(t *testing.T) string {
	t.Helper()
	id := uuid.New()
	token, err := e.auth.IssueJWT(id, id.String()[:8]+"@itest.simo")
	if err != nil {
		t.Fatalf("failed to issue token: %v", err)
	}
	return token
}

// doSync posts a sync request with the given bearer token and returns the decoded response data.
func (e *syncEnv) doSync(t *testing.T, token string, req model.SyncRequest) model.SyncResponseData {
	t.Helper()
	body, err := json.Marshal(req)
	if err != nil {
		t.Fatalf("failed to marshal sync request: %v", err)
	}
	httpReq := httptest.NewRequest(http.MethodPost, "/api/v1/sync", bytes.NewReader(body))
	httpReq.Header.Set("Authorization", "Bearer "+token)
	rec := httptest.NewRecorder()
	e.router.ServeHTTP(rec, httpReq)
	if rec.Code != http.StatusOK {
		t.Fatalf("sync failed with status %d: %s", rec.Code, rec.Body.String())
	}
	var res struct {
		Data model.SyncResponseData `json:"data"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &res); err != nil {
		t.Fatalf("failed to decode sync response: %v", err)
	}
	return res.Data
}

// listWallets calls GET /api/v1/wallets and returns the decoded wallets.
func (e *syncEnv) listWallets(t *testing.T, token string) []repository.WalletWithBalance {
	t.Helper()
	httpReq := httptest.NewRequest(http.MethodGet, "/api/v1/wallets", nil)
	httpReq.Header.Set("Authorization", "Bearer "+token)
	rec := httptest.NewRecorder()
	e.router.ServeHTTP(rec, httpReq)
	if rec.Code != http.StatusOK {
		t.Fatalf("list wallets failed with status %d: %s", rec.Code, rec.Body.String())
	}
	var res struct {
		Data []repository.WalletWithBalance `json:"data"`
	}
	if err := json.Unmarshal(rec.Body.Bytes(), &res); err != nil {
		t.Fatalf("failed to decode wallets: %v", err)
	}
	return res.Data
}

// wallet builds a WalletSync with the given id, name, balance and client update time.
func wallet(id uuid.UUID, name string, balance float64, updated time.Time) model.WalletSync {
	return model.WalletSync{
		ID: id, Name: name, Type: "cash", InitialBalance: balance, Color: "#10B981", Icon: "wallet",
		ClientCreatedAt: model.NewFlexibleTime(updated), ClientUpdatedAt: model.NewFlexibleTime(updated),
	}
}

// expense builds an expense TransactionSync against the given wallet.
func expense(walletID uuid.UUID, amount float64, at time.Time) model.TransactionSync {
	return model.TransactionSync{
		ID: uuid.New(), WalletID: &walletID, Amount: amount, Type: "expense", TransactionDate: at.Format("2006-01-02"),
		ClientCreatedAt: model.NewFlexibleTime(at), ClientUpdatedAt: model.NewFlexibleTime(at),
	}
}

// TestSync_CannotOverwriteAnotherUsersRecord verifies that knowing another user's record UUID
// does not allow overwriting or tombstoning it.
func TestSync_CannotOverwriteAnotherUsersRecord(t *testing.T) {
	env := newSyncEnv(t)
	victim, attacker := env.newUserToken(t), env.newUserToken(t)
	walletID := uuid.New()
	now := time.Now().UTC()

	env.doSync(t, victim, model.SyncRequest{Mutations: model.SyncMutations{
		Wallets: []model.WalletSync{wallet(walletID, "Victim savings", 5_000_000, now)},
	}})

	// Attacker reuses the UUID with a newer client timestamp (LWW would otherwise let it win).
	hijacked := wallet(walletID, "pwned", 0, now.Add(time.Hour))
	deletedAt := model.NewFlexibleTime(now.Add(time.Hour))
	hijacked.DeletedAt = &deletedAt
	env.doSync(t, attacker, model.SyncRequest{Mutations: model.SyncMutations{
		Wallets:   []model.WalletSync{hijacked},
		Deletions: []model.TombstoneDeletion{{TableName: "wallets", ID: walletID.String(), DeletedAt: deletedAt}},
	}})

	wallets := env.listWallets(t, victim)
	if len(wallets) != 1 {
		t.Fatalf("victim should still see exactly 1 wallet, got %d", len(wallets))
	}
	if wallets[0].Name != "Victim savings" || wallets[0].InitialBalance != 5_000_000 {
		t.Fatalf("victim wallet was modified by another user: %+v", wallets[0].WalletSync)
	}
	if got := env.listWallets(t, attacker); len(got) != 0 {
		t.Fatalf("attacker must not see the victim's wallet, got %d wallets", len(got))
	}
}

// TestWalletBalance_IgnoresOtherUsersTransactions verifies that transactions another user files
// against your wallet UUID do not change your balance.
func TestWalletBalance_IgnoresOtherUsersTransactions(t *testing.T) {
	env := newSyncEnv(t)
	owner, other := env.newUserToken(t), env.newUserToken(t)
	walletID := uuid.New()
	now := time.Now().UTC()

	env.doSync(t, owner, model.SyncRequest{Mutations: model.SyncMutations{
		Wallets:      []model.WalletSync{wallet(walletID, "Cash", 1_000_000, now)},
		Transactions: []model.TransactionSync{expense(walletID, 100_000, now)},
	}})
	env.doSync(t, other, model.SyncRequest{Mutations: model.SyncMutations{
		Transactions: []model.TransactionSync{expense(walletID, 900_000, now)},
	}})

	wallets := env.listWallets(t, owner)
	if len(wallets) != 1 {
		t.Fatalf("expected 1 wallet, got %d", len(wallets))
	}
	if wallets[0].CurrentBalance != 900_000 {
		t.Fatalf("expected balance 900000 (1M - own 100k), got %v", wallets[0].CurrentBalance)
	}
}

// TestSync_CursorExcludesOwnWritesAndIncludesLaterOnes verifies the returned server_time works as
// a cursor: a device does not re-pull what it just pushed, but does pull what others push later.
func TestSync_CursorExcludesOwnWritesAndIncludesLaterOnes(t *testing.T) {
	env := newSyncEnv(t)
	user := env.newUserToken(t)
	now := time.Now().UTC()

	first := env.doSync(t, user, model.SyncRequest{DeviceID: "a", Mutations: model.SyncMutations{
		Wallets: []model.WalletSync{wallet(uuid.New(), "A1", 1, now)},
	}})
	cursorA := model.NewFlexibleTime(first.ServerTime)

	again := env.doSync(t, user, model.SyncRequest{DeviceID: "a", LastSyncedServerTime: &cursorA})
	if len(again.Changes.Wallets) != 0 {
		t.Fatalf("device A re-pulled its own writes: %d wallets", len(again.Changes.Wallets))
	}
	if !again.ServerTime.After(first.ServerTime) {
		t.Fatalf("server_time must increase between cycles: %v -> %v", first.ServerTime, again.ServerTime)
	}

	env.doSync(t, user, model.SyncRequest{DeviceID: "b", Mutations: model.SyncMutations{
		Wallets: []model.WalletSync{wallet(uuid.New(), "B1", 2, now)},
	}})
	pulled := env.doSync(t, user, model.SyncRequest{DeviceID: "a", LastSyncedServerTime: &cursorA})
	if len(pulled.Changes.Wallets) != 1 || pulled.Changes.Wallets[0].Name != "B1" {
		t.Fatalf("device A should pull exactly B1, got %+v", pulled.Changes.Wallets)
	}
}

// TestSync_ConcurrentDevicesNeverLoseRows hammers one user with concurrent pushing devices and
// checks that every device's cursor chain eventually observes every row exactly as committed.
func TestSync_ConcurrentDevicesNeverLoseRows(t *testing.T) {
	env := newSyncEnv(t)
	user := env.newUserToken(t)
	const devices, rounds = 6, 8

	var mu sync.Mutex
	pushed := map[uuid.UUID]bool{}
	cursors := make([]*model.FlexibleTime, devices)
	seen := make([]map[uuid.UUID]bool, devices)
	for i := range seen {
		seen[i] = map[uuid.UUID]bool{}
	}

	var wg sync.WaitGroup
	for d := range devices {
		wg.Add(1)
		go func() {
			defer wg.Done()
			for range rounds {
				id := uuid.New()
				mu.Lock()
				pushed[id] = true
				mu.Unlock()
				res := env.doSync(t, user, model.SyncRequest{
					LastSyncedServerTime: cursors[d],
					Mutations:            model.SyncMutations{Wallets: []model.WalletSync{wallet(id, "w", 1, time.Now().UTC())}},
				})
				seen[d][id] = true
				for _, w := range res.Changes.Wallets {
					seen[d][w.ID] = true
				}
				c := model.NewFlexibleTime(res.ServerTime)
				cursors[d] = &c
			}
		}()
	}
	wg.Wait()

	// One final pull per device must complete its view.
	for d := range devices {
		res := env.doSync(t, user, model.SyncRequest{LastSyncedServerTime: cursors[d]})
		for _, w := range res.Changes.Wallets {
			seen[d][w.ID] = true
		}
		for id := range pushed {
			if !seen[d][id] {
				t.Errorf("device %d never received wallet %s", d, id)
			}
		}
	}
}

// TestDB_RetryGivesUpOnUnreachableDatabase verifies the startup retry returns an error instead of hanging.
func TestDB_RetryGivesUpOnUnreachableDatabase(t *testing.T) {
	start := time.Now()
	_, err := repository.InitDBWithRetry(context.Background(), "postgres://u:p@127.0.0.1:1/none?sslmode=disable", 2*time.Second)
	if err == nil {
		t.Fatal("expected error for unreachable database")
	}
	if elapsed := time.Since(start); elapsed > 5*time.Second {
		t.Fatalf("retry exceeded its budget: %s", elapsed)
	}
}

// TestSync_ReportsRecordsOwnedByAnotherUser verifies that pushes and tombstones targeting IDs owned by
// another user are listed in the response instead of being silently dropped, while the caller's own
// records in the same push are still applied.
func TestSync_ReportsRecordsOwnedByAnotherUser(t *testing.T) {
	env := newSyncEnv(t)
	owner, other := env.newUserToken(t), env.newUserToken(t)
	walletID := uuid.New()
	now := time.Now().UTC()
	tx := expense(walletID, 50_000, now)

	first := env.doSync(t, owner, model.SyncRequest{Mutations: model.SyncMutations{
		Wallets:      []model.WalletSync{wallet(walletID, "Owner cash", 1_000_000, now)},
		Transactions: []model.TransactionSync{tx},
	}})
	if len(first.Rejected) != 0 {
		t.Fatalf("owner's own push must not be rejected, got %+v", first.Rejected)
	}

	later := now.Add(time.Hour)
	tx.ClientUpdatedAt = model.NewFlexibleTime(later)
	ownWalletID := uuid.New()
	res := env.doSync(t, other, model.SyncRequest{Mutations: model.SyncMutations{
		Wallets: []model.WalletSync{
			wallet(walletID, "Hijack", 0, later),
			wallet(ownWalletID, "Other cash", 10, later),
		},
		Transactions: []model.TransactionSync{tx},
		Deletions: []model.TombstoneDeletion{
			{TableName: "transactions", ID: tx.ID.String(), DeletedAt: model.NewFlexibleTime(later)},
		},
	}})

	want := map[model.RejectedRecord]bool{
		{Table: "wallets", ID: walletID.String(), Reason: model.RejectReasonOwnedByAnotherUser}:   true,
		{Table: "transactions", ID: tx.ID.String(), Reason: model.RejectReasonOwnedByAnotherUser}: true,
	}
	if len(res.Rejected) != 3 {
		t.Fatalf("expected 3 rejections (wallet, transaction, transaction tombstone), got %+v", res.Rejected)
	}
	for _, r := range res.Rejected {
		if !want[r] {
			t.Fatalf("unexpected rejection %+v", r)
		}
	}

	otherWallets := env.listWallets(t, other)
	if len(otherWallets) != 1 || otherWallets[0].ID != ownWalletID {
		t.Fatalf("other user's own wallet must still be stored, got %+v", otherWallets)
	}
	ownerWallets := env.listWallets(t, owner)
	if len(ownerWallets) != 1 || ownerWallets[0].Name != "Owner cash" || ownerWallets[0].CurrentBalance != 950_000 {
		t.Fatalf("owner data must be untouched, got %+v", ownerWallets)
	}
}

// TestSync_StaleWriteIsNotReportedAsRejected verifies that a Last-Write-Wins skip of the caller's own
// older edit is not confused with an ownership rejection.
func TestSync_StaleWriteIsNotReportedAsRejected(t *testing.T) {
	env := newSyncEnv(t)
	user := env.newUserToken(t)
	walletID := uuid.New()
	now := time.Now().UTC()

	env.doSync(t, user, model.SyncRequest{Mutations: model.SyncMutations{
		Wallets: []model.WalletSync{wallet(walletID, "Newer", 2, now)},
	}})
	res := env.doSync(t, user, model.SyncRequest{Mutations: model.SyncMutations{
		Wallets: []model.WalletSync{wallet(walletID, "Older", 1, now.Add(-time.Hour))},
	}})
	if len(res.Rejected) != 0 {
		t.Fatalf("stale own write must not be reported, got %+v", res.Rejected)
	}
	if got := env.listWallets(t, user); len(got) != 1 || got[0].Name != "Newer" {
		t.Fatalf("newer copy must win, got %+v", got)
	}
}

// TestSync_SharedCategoryIDIsNotRejected verifies that category IDs, which are scoped per user,
// never produce rejections when two users use the same ID.
func TestSync_SharedCategoryIDIsNotRejected(t *testing.T) {
	env := newSyncEnv(t)
	a, b := env.newUserToken(t), env.newUserToken(t)
	now := model.NewFlexibleTime(time.Now().UTC())
	icon, color := "food", "#F59E0B"
	cat := model.CategorySync{ID: "food", Name: "Food", Type: "expense", Icon: &icon, Color: &color,
		ClientCreatedAt: now, ClientUpdatedAt: now}

	env.doSync(t, a, model.SyncRequest{Mutations: model.SyncMutations{Categories: []model.CategorySync{cat}}})
	res := env.doSync(t, b, model.SyncRequest{Mutations: model.SyncMutations{
		Categories: []model.CategorySync{cat},
		Deletions:  []model.TombstoneDeletion{{TableName: "categories", ID: "missing-for-b", DeletedAt: now}},
	}})
	if len(res.Rejected) != 0 {
		t.Fatalf("per-user category IDs must not be rejected, got %+v", res.Rejected)
	}
}

// TestSync_DanglingForeignKeysDoNotAbortSync verifies that pushing recurring_configs or transactions
// referencing non-existent or foreign wallets/recurring_configs nullifies those optional FKs safely,
// and pushing child records with missing required parents reports them as missing_parent rejections
// without failing the sync cycle with HTTP 500.
func TestSync_DanglingForeignKeysDoNotAbortSync(t *testing.T) {
	env := newSyncEnv(t)
	user := env.newUserToken(t)
	now := model.NewFlexibleTime(time.Now().UTC())

	missingWalletID := uuid.New()
	missingRecurringID := uuid.New()
	missingGoalID := uuid.New()
	missingLoanID := uuid.New()

	rcID := uuid.New()
	txID := uuid.New()
	transferID := uuid.New()
	goalLogID := uuid.New()
	loanTxID := uuid.New()

	res := env.doSync(t, user, model.SyncRequest{
		DeviceID: "dangling_fk_device",
		Mutations: model.SyncMutations{
			RecurringConfigs: []model.RecurringConfigSync{
				{
					ID:              rcID,
					WalletID:        &missingWalletID,
					Name:            "Monthly Internet",
					Amount:          330_000,
					Type:            "expense",
					Frequency:       "monthly",
					Interval:        1,
					NextRun:         now,
					IsActive:        true,
					ClientCreatedAt: now,
					ClientUpdatedAt: now,
				},
			},
			Transactions: []model.TransactionSync{
				{
					ID:                txID,
					WalletID:          &missingWalletID,
					RecurringConfigID: &missingRecurringID,
					Amount:            50_000,
					Type:              "expense",
					TransactionDate:   "2026-11-22",
					ClientCreatedAt:   now,
					ClientUpdatedAt:   now,
				},
			},
			WalletTransfers: []model.WalletTransferSync{
				{
					ID:                  transferID,
					SourceWalletID:      missingWalletID,
					DestinationWalletID: uuid.New(),
					Amount:              100_000,
					TransferDate:        now,
					ClientCreatedAt:     now,
					ClientUpdatedAt:     now,
				},
			},
			SavingGoalLogs: []model.SavingGoalLogSync{
				{
					ID:              goalLogID,
					GoalID:          missingGoalID,
					Amount:          200_000,
					Type:            "deposit",
					LogDate:         now,
					ClientCreatedAt: now,
					ClientUpdatedAt: now,
				},
			},
			LoanTransactions: []model.LoanTransactionSync{
				{
					ID:              loanTxID,
					LoanID:          missingLoanID,
					Amount:          500_000,
					Type:            "repay",
					Date:            now,
					ClientCreatedAt: now,
					ClientUpdatedAt: now,
				},
			},
		},
	})

	if len(res.Changes.RecurringConfigs) != 1 {
		t.Fatalf("expected 1 recurring_config persisted, got %d", len(res.Changes.RecurringConfigs))
	}
	if res.Changes.RecurringConfigs[0].WalletID != nil {
		t.Errorf("expected dangling wallet_id on recurring_config to be nullified, got %v", res.Changes.RecurringConfigs[0].WalletID)
	}

	if len(res.Changes.Transactions) != 1 {
		t.Fatalf("expected 1 transaction persisted, got %d", len(res.Changes.Transactions))
	}
	if res.Changes.Transactions[0].WalletID != nil || res.Changes.Transactions[0].RecurringConfigID != nil {
		t.Errorf("expected dangling FKs on transaction to be nullified, got wallet=%v recurring=%v",
			res.Changes.Transactions[0].WalletID, res.Changes.Transactions[0].RecurringConfigID)
	}

	wantRejected := map[model.RejectedRecord]bool{
		{Table: "wallet_transfers", ID: transferID.String(), Reason: model.RejectReasonMissingParent}: true,
		{Table: "saving_goal_logs", ID: goalLogID.String(), Reason: model.RejectReasonMissingParent}:  true,
		{Table: "loan_transactions", ID: loanTxID.String(), Reason: model.RejectReasonMissingParent}:  true,
	}
	if len(res.Rejected) != 3 {
		t.Fatalf("expected 3 missing_parent rejections, got %+v", res.Rejected)
	}
	for _, r := range res.Rejected {
		if !wantRejected[r] {
			t.Fatalf("unexpected rejection record: %+v", r)
		}
	}
}
