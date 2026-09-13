package service

import (
	"context"
	"fmt"

	"github.com/google/uuid"

	"simo-server/internal/model"
	"simo-server/internal/repository"
	"simo-server/internal/sse"
)

// SyncService coordinates the synchronization business logic between clients and the database.
type SyncService struct {
	syncRepo *repository.SyncRepository
	sseHub   *sse.Hub
}

// NewSyncService creates a new SyncService instance.
//
// @param syncRepo *repository.SyncRepository
// @param sseHub *sse.Hub (optional)
// @returns *SyncService
func NewSyncService(syncRepo *repository.SyncRepository, sseHub *sse.Hub) *SyncService {
	return &SyncService{
		syncRepo: syncRepo,
		sseHub:   sseHub,
	}
}

// Sync processes an incoming sync request containing client mutations and returns remote deltas.
//
// @param ctx context.Context
// @param userID uuid.UUID authenticated user ID
// @param req *model.SyncRequest incoming mutations and sync cursor
// @returns *model.SyncResponseData with current server timestamp and changes
func (s *SyncService) Sync(ctx context.Context, userID uuid.UUID, req *model.SyncRequest) (*model.SyncResponseData, error) {
	if req == nil {
		return nil, fmt.Errorf("sync request payload is nil")
	}

	serverTime, changes, err := s.syncRepo.ProcessSyncCycle(
		ctx,
		userID,
		req.LastSyncedServerTime,
		&req.Mutations,
	)
	if err != nil {
		return nil, fmt.Errorf("failed to process sync cycle: %w", err)
	}

	// If the client pushed any mutations, notify other connected devices via SSE
	if s.sseHub != nil && s.hasMutations(&req.Mutations) {
		tables := s.extractAffectedTables(&req.Mutations)
		s.sseHub.Broadcast(userID, &sse.SyncEvent{
			Type:           "data_changed",
			SourceClientID: req.DeviceID,
			TableNames:     tables,
			ServerTime:     serverTime,
		})
	}

	return &model.SyncResponseData{
		ServerTime: serverTime,
		Changes:    *changes,
	}, nil
}

// hasMutations checks if the request payload contains any modifications or deletions.
func (s *SyncService) hasMutations(m *model.SyncMutations) bool {
	if m == nil {
		return false
	}
	return len(m.Wallets) > 0 ||
		len(m.WalletTransfers) > 0 ||
		len(m.Categories) > 0 ||
		len(m.Transactions) > 0 ||
		len(m.MonthlyBudgets) > 0 ||
		len(m.CategoryMonthlyBudgets) > 0 ||
		len(m.SavingGoals) > 0 ||
		len(m.SavingGoalLogs) > 0 ||
		len(m.LoanContacts) > 0 ||
		len(m.LoanTransactions) > 0 ||
		len(m.RecurringConfigs) > 0 ||
		len(m.Deletions) > 0
}

// extractAffectedTables returns a list of table names present in the mutations payload.
func (s *SyncService) extractAffectedTables(m *model.SyncMutations) []string {
	var tables []string
	if len(m.Wallets) > 0 {
		tables = append(tables, "wallets")
	}
	if len(m.WalletTransfers) > 0 {
		tables = append(tables, "wallet_transfers")
	}
	if len(m.Categories) > 0 {
		tables = append(tables, "categories")
	}
	if len(m.Transactions) > 0 {
		tables = append(tables, "transactions")
	}
	if len(m.MonthlyBudgets) > 0 {
		tables = append(tables, "monthly_budgets")
	}
	if len(m.CategoryMonthlyBudgets) > 0 {
		tables = append(tables, "category_monthly_budgets")
	}
	if len(m.SavingGoals) > 0 {
		tables = append(tables, "saving_goals")
	}
	if len(m.SavingGoalLogs) > 0 {
		tables = append(tables, "saving_goal_logs")
	}
	if len(m.LoanContacts) > 0 {
		tables = append(tables, "loan_contacts")
	}
	if len(m.LoanTransactions) > 0 {
		tables = append(tables, "loan_transactions")
	}
	if len(m.RecurringConfigs) > 0 {
		tables = append(tables, "recurring_configs")
	}
	if len(m.Deletions) > 0 {
		tables = append(tables, "deletions")
	}
	return tables
}
