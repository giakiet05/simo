package service

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgxpool"
)

// DashboardService calculates high-level financial metrics for the web dashboard.
type DashboardService struct {
	pool *pgxpool.Pool
}

// NewDashboardService creates a new DashboardService.
//
// @param pool *pgxpool.Pool
// @returns *DashboardService
func NewDashboardService(pool *pgxpool.Pool) *DashboardService {
	return &DashboardService{pool: pool}
}

// CategoryExpenseBreakdown represents spending grouped by category.
type CategoryExpenseBreakdown struct {
	CategoryID   string  `json:"category_id"`
	CategoryName string  `json:"category_name"`
	Color        string  `json:"color"`
	TotalAmount  float64 `json:"total_amount"`
	Percentage   float64 `json:"percentage"`
}

// DashboardSummary represents the complete metrics payload for the dashboard view.
type DashboardSummary struct {
	TotalAssets     float64                    `json:"total_assets"`
	MonthIncome     float64                    `json:"month_income"`
	MonthExpense    float64                    `json:"month_expense"`
	MonthBalance    float64                    `json:"month_balance"`
	MonthBudget     float64                    `json:"month_budget"`
	BudgetRemaining float64                    `json:"budget_remaining"`
	CategoryShares  []CategoryExpenseBreakdown `json:"category_shares"`
}

// GetSummary computes financial KPIs for a given user and calendar month.
//
// @param ctx context.Context
// @param userID uuid.UUID
// @param year int
// @param month int
// @returns *DashboardSummary, error
func (s *DashboardService) GetSummary(ctx context.Context, userID uuid.UUID, year int, month int) (*DashboardSummary, error) {
	if year <= 0 || month <= 0 || month > 12 {
		now := time.Now()
		year = now.Year()
		month = int(now.Month())
	}

	startDate := fmt.Sprintf("%04d-%02d-01", year, month)
	// Calculate end of month
	endMonth := month + 1
	endYear := year
	if endMonth > 12 {
		endMonth = 1
		endYear++
	}
	endDate := fmt.Sprintf("%04d-%02d-01", endYear, endMonth)

	// 1. Total Assets: sum of all wallets with exclude_from_total = false
	var totalAssets float64
	err := s.pool.QueryRow(ctx, `
		SELECT COALESCE(SUM(
			w.initial_balance 
				+ COALESCE((SELECT SUM(amount) FROM transactions WHERE wallet_id = w.id AND type = 'income' AND deleted_at IS NULL), 0)
				- COALESCE((SELECT SUM(amount) FROM transactions WHERE wallet_id = w.id AND type = 'expense' AND deleted_at IS NULL), 0)
				+ COALESCE((SELECT SUM(amount) FROM wallet_transfers WHERE destination_wallet_id = w.id AND deleted_at IS NULL), 0)
				- COALESCE((SELECT SUM(amount + fee) FROM wallet_transfers WHERE source_wallet_id = w.id AND deleted_at IS NULL), 0)
		), 0)
		FROM wallets w
		WHERE w.user_id = $1 AND w.exclude_from_total = false AND w.deleted_at IS NULL;
	`, userID).Scan(&totalAssets)
	if err != nil {
		return nil, fmt.Errorf("failed to query total assets: %w", err)
	}

	// 2. Month Income & Expense
	var monthIncome, monthExpense float64
	err = s.pool.QueryRow(ctx, `
		SELECT 
			COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END), 0),
			COALESCE(SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END), 0)
		FROM transactions
		WHERE user_id = $1 AND transaction_date >= $2 AND transaction_date < $3 AND deleted_at IS NULL;
	`, userID, startDate, endDate).Scan(&monthIncome, &monthExpense)
	if err != nil {
		return nil, fmt.Errorf("failed to query monthly cashflow: %w", err)
	}

	// 3. Monthly Budget
	var monthBudget float64
	_ = s.pool.QueryRow(ctx, `
		SELECT amount FROM monthly_budgets
		WHERE user_id = $1 AND year = $2 AND month = $3 AND deleted_at IS NULL;
	`, userID, year, month).Scan(&monthBudget)

	// 4. Category Expense Breakdown
	rows, err := s.pool.Query(ctx, `
		SELECT 
			COALESCE(t.category_id, 'uncategorized'),
			COALESCE(c.name, 'Chưa phân loại'),
			COALESCE(c.color, '#94A3B8'),
			SUM(t.amount) as total
		FROM transactions t
		LEFT JOIN categories c ON c.id = t.category_id AND c.user_id = t.user_id
		WHERE t.user_id = $1 AND t.type = 'expense' AND t.transaction_date >= $2 AND t.transaction_date < $3 AND t.deleted_at IS NULL
		GROUP BY t.category_id, c.name, c.color
		ORDER BY total DESC;
	`, userID, startDate, endDate)
	if err != nil {
		return nil, fmt.Errorf("failed to query category shares: %w", err)
	}
	defer rows.Close()

	shares := make([]CategoryExpenseBreakdown, 0)
	for rows.Next() {
		var cat CategoryExpenseBreakdown
		if err := rows.Scan(&cat.CategoryID, &cat.CategoryName, &cat.Color, &cat.TotalAmount); err != nil {
			return nil, err
		}
		if monthExpense > 0 {
			cat.Percentage = (cat.TotalAmount / monthExpense) * 100
		}
		shares = append(shares, cat)
	}

	return &DashboardSummary{
		TotalAssets:     totalAssets,
		MonthIncome:     monthIncome,
		MonthExpense:    monthExpense,
		MonthBalance:    monthIncome - monthExpense,
		MonthBudget:     monthBudget,
		BudgetRemaining: monthBudget - monthExpense,
		CategoryShares:  shares,
	}, nil
}
