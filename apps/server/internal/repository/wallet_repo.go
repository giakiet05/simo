package repository

import (
	"context"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"

	"simo-server/internal/model"
)

// WalletRepository handles querying wallets and calculating live balances for Web clients.
type WalletRepository struct {
	pool *pgxpool.Pool
}

// NewWalletRepository creates a new WalletRepository.
//
// @param pool *pgxpool.Pool
// @returns *WalletRepository
func NewWalletRepository(pool *pgxpool.Pool) *WalletRepository {
	return &WalletRepository{pool: pool}
}

// WalletWithBalance extends WalletSync with live calculated current balance.
type WalletWithBalance struct {
	model.WalletSync
	CurrentBalance float64 `json:"current_balance"`
}

// ListWalletsWithBalance returns all user wallets with their live calculated balances.
//
// @param ctx context.Context
// @param userID uuid.UUID
// @returns []WalletWithBalance, error
func (r *WalletRepository) ListWalletsWithBalance(ctx context.Context, userID uuid.UUID) ([]WalletWithBalance, error) {
	query := `
		SELECT 
			w.id, w.name, w.type, w.initial_balance, w.color, w.icon, w.currency,
			w.is_default, w.exclude_from_total, w.priority, w.client_created_at, w.client_updated_at,
			w.initial_balance 
				+ COALESCE((SELECT SUM(amount) FROM transactions WHERE wallet_id = w.id AND type = 'income' AND deleted_at IS NULL), 0)
				- COALESCE((SELECT SUM(amount) FROM transactions WHERE wallet_id = w.id AND type = 'expense' AND deleted_at IS NULL), 0)
				+ COALESCE((SELECT SUM(amount) FROM wallet_transfers WHERE destination_wallet_id = w.id AND deleted_at IS NULL), 0)
				- COALESCE((SELECT SUM(amount + fee) FROM wallet_transfers WHERE source_wallet_id = w.id AND deleted_at IS NULL), 0) as current_balance
		FROM wallets w
		WHERE w.user_id = $1 AND w.deleted_at IS NULL
		ORDER BY w.priority DESC, w.client_created_at ASC;
	`
	rows, err := r.pool.Query(ctx, query, userID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	list := make([]WalletWithBalance, 0)
	for rows.Next() {
		var wb WalletWithBalance
		if err := rows.Scan(
			&wb.ID, &wb.Name, &wb.Type, &wb.InitialBalance, &wb.Color, &wb.Icon, &wb.Currency,
			&wb.IsDefault, &wb.ExcludeFromTotal, &wb.Priority, &wb.ClientCreatedAt, &wb.ClientUpdatedAt,
			&wb.CurrentBalance,
		); err != nil {
			return nil, err
		}
		list = append(list, wb)
	}

	return list, nil
}
