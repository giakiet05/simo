package model

import (
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"strings"
	"time"

	"github.com/google/uuid"
)

// FlexibleTime wraps time.Time to support flexible timestamp and date formats during JSON deserialization.
type FlexibleTime struct {
	time.Time
}

// NewFlexibleTime creates a FlexibleTime instance from standard time.Time.
//
// @param t time.Time
// @returns FlexibleTime
func NewFlexibleTime(t time.Time) FlexibleTime {
	return FlexibleTime{Time: t}
}

// UnmarshalJSON parses JSON strings using multiple standard and non-standard time formats.
//
// @param b []byte JSON string bytes
// @returns error if no format matches
func (t *FlexibleTime) UnmarshalJSON(b []byte) error {
	s := strings.Trim(string(b), "\"")
	if s == "" || s == "null" {
		t.Time = time.Time{}
		return nil
	}

	formats := []string{
		time.RFC3339Nano,
		time.RFC3339,
		"2006-01-02T15:04:05.999999999Z07:00",
		"2006-01-02T15:04:05.999999999",
		"2006-01-02T15:04:05",
		"2006-01-02 15:04:05.999999999",
		"2006-01-02 15:04:05",
		"2006-01-02",
	}

	var parsed time.Time
	var err error
	for _, f := range formats {
		parsed, err = time.Parse(f, s)
		if err == nil {
			t.Time = parsed.UTC()
			return nil
		}
	}
	return fmt.Errorf("cannot parse time string %q: %w", s, err)
}

// MarshalJSON formats FlexibleTime into RFC3339Nano UTC string or null.
//
// @returns []byte JSON string, error
func (t FlexibleTime) MarshalJSON() ([]byte, error) {
	if t.IsZero() {
		return []byte("null"), nil
	}
	return json.Marshal(t.UTC().Format(time.RFC3339Nano))
}

// Value implements driver.Valuer for PostgreSQL operations.
//
// @returns driver.Value, error
func (t FlexibleTime) Value() (driver.Value, error) {
	if t.IsZero() {
		return nil, nil
	}
	return t.Time, nil
}

// Scan implements sql.Scanner for PostgreSQL operations.
//
// @param value interface{}
// @returns error
func (t *FlexibleTime) Scan(value interface{}) error {
	if value == nil {
		t.Time = time.Time{}
		return nil
	}
	switch v := value.(type) {
	case time.Time:
		t.Time = v
		return nil
	case string:
		return t.UnmarshalJSON([]byte(`"` + v + `"`))
	case []byte:
		return t.UnmarshalJSON([]byte(`"` + string(v) + `"`))
	default:
		return fmt.Errorf("cannot scan %T into FlexibleTime", value)
	}
}

// TombstoneDeletion represents a deleted entity for synchronization.
type TombstoneDeletion struct {
	TableName string       `json:"table_name"`
	ID        string       `json:"id"`
	DeletedAt FlexibleTime `json:"deleted_at"`
}

// WalletSync represents a Wallet entity in the sync payload.
type WalletSync struct {
	ID               uuid.UUID     `json:"id"`
	Name             string        `json:"name"`
	Type             string        `json:"type"`
	InitialBalance   float64       `json:"initial_balance"`
	Color            string        `json:"color"`
	Icon             string        `json:"icon"`
	Currency         *string       `json:"currency,omitempty"`
	IsDefault        bool          `json:"is_default"`
	ExcludeFromTotal bool          `json:"exclude_from_total"`
	Priority         int           `json:"priority"`
	ClientCreatedAt  FlexibleTime  `json:"created_at"`
	ClientUpdatedAt  FlexibleTime  `json:"updated_at"`
	ServerUpdatedAt  FlexibleTime  `json:"server_updated_at,omitempty"`
	DeletedAt        *FlexibleTime `json:"deleted_at,omitempty"`
}

// WalletTransferSync represents an atomic wallet transfer record.
type WalletTransferSync struct {
	ID                  uuid.UUID     `json:"id"`
	SourceWalletID      uuid.UUID     `json:"source_wallet_id"`
	DestinationWalletID uuid.UUID     `json:"destination_wallet_id"`
	Amount              float64       `json:"amount"`
	Fee                 float64       `json:"fee"`
	TransferDate        FlexibleTime  `json:"transfer_date"`
	Note                *string       `json:"note,omitempty"`
	ClientCreatedAt     FlexibleTime  `json:"created_at"`
	ClientUpdatedAt     FlexibleTime  `json:"updated_at"`
	ServerUpdatedAt     FlexibleTime  `json:"server_updated_at,omitempty"`
	DeletedAt           *FlexibleTime `json:"deleted_at,omitempty"`
}

// CategorySync represents a Category entity in the sync payload.
type CategorySync struct {
	ID              string        `json:"id"`
	Name            string        `json:"name"`
	Type            string        `json:"type"` // income or expense
	Icon            *string       `json:"icon,omitempty"`
	Color           *string       `json:"color,omitempty"`
	BudgetLimit     *float64      `json:"budget_limit,omitempty"`
	ClientCreatedAt FlexibleTime  `json:"created_at"`
	ClientUpdatedAt FlexibleTime  `json:"updated_at"`
	ServerUpdatedAt FlexibleTime  `json:"server_updated_at,omitempty"`
	DeletedAt       *FlexibleTime `json:"deleted_at,omitempty"`
}

// TransactionSync represents an individual financial transaction.
type TransactionSync struct {
	ID                uuid.UUID     `json:"id"`
	WalletID          *uuid.UUID    `json:"wallet_id,omitempty"`
	CategoryID        *string       `json:"category_id,omitempty"`
	RecurringConfigID *uuid.UUID    `json:"recurring_config_id,omitempty"`
	Amount            float64       `json:"amount"`
	Formula           *string       `json:"formula,omitempty"`
	Note              *string       `json:"note,omitempty"`
	Type              string        `json:"type"` // income or expense
	TransactionDate   string        `json:"transaction_date"` // YYYY-MM-DD
	ClientCreatedAt   FlexibleTime  `json:"created_at"`
	ClientUpdatedAt   FlexibleTime  `json:"updated_at"`
	ServerUpdatedAt   FlexibleTime  `json:"server_updated_at,omitempty"`
	DeletedAt         *FlexibleTime `json:"deleted_at,omitempty"`
}

// MonthlyBudgetSync represents a monthly budget limit.
type MonthlyBudgetSync struct {
	ID              uuid.UUID     `json:"id"`
	Year            int           `json:"year"`
	Month           int           `json:"month"`
	Amount          float64       `json:"amount"`
	ClientCreatedAt FlexibleTime  `json:"created_at"`
	ClientUpdatedAt FlexibleTime  `json:"updated_at"`
	ServerUpdatedAt FlexibleTime  `json:"server_updated_at,omitempty"`
	DeletedAt       *FlexibleTime `json:"deleted_at,omitempty"`
}

// CategoryMonthlyBudgetSync represents a category-specific monthly budget limit.
type CategoryMonthlyBudgetSync struct {
	ID              uuid.UUID     `json:"id"`
	CategoryID      string        `json:"category_id"`
	Year            int           `json:"year"`
	Month           int           `json:"month"`
	Amount          float64       `json:"amount"`
	ClientCreatedAt FlexibleTime  `json:"created_at"`
	ClientUpdatedAt FlexibleTime  `json:"updated_at"`
	ServerUpdatedAt FlexibleTime  `json:"server_updated_at,omitempty"`
	DeletedAt       *FlexibleTime `json:"deleted_at,omitempty"`
}

// SavingGoalSync represents a savings goal entity.
type SavingGoalSync struct {
	ID              uuid.UUID     `json:"id"`
	Name            string        `json:"name"`
	TargetAmount    float64       `json:"target_amount"`
	CurrentAmount   float64       `json:"current_amount"`
	TargetDate      *string       `json:"target_date,omitempty"`
	Color           *string       `json:"color,omitempty"`
	Icon            *string       `json:"icon,omitempty"`
	Note            *string       `json:"note,omitempty"`
	Status          string        `json:"status"`
	ClientCreatedAt FlexibleTime  `json:"created_at"`
	ClientUpdatedAt FlexibleTime  `json:"updated_at"`
	ServerUpdatedAt FlexibleTime  `json:"server_updated_at,omitempty"`
	DeletedAt       *FlexibleTime `json:"deleted_at,omitempty"`
}

// SavingGoalLogSync represents an individual savings goal deposit/withdrawal log.
type SavingGoalLogSync struct {
	ID              uuid.UUID     `json:"id"`
	GoalID          uuid.UUID     `json:"goal_id"`
	Amount          float64       `json:"amount"`
	Type            string        `json:"type"` // deposit or withdraw
	LogDate         FlexibleTime  `json:"log_date"`
	Note            *string       `json:"note,omitempty"`
	ClientCreatedAt FlexibleTime  `json:"created_at"`
	ClientUpdatedAt FlexibleTime  `json:"updated_at"`
	ServerUpdatedAt FlexibleTime  `json:"server_updated_at,omitempty"`
	DeletedAt       *FlexibleTime `json:"deleted_at,omitempty"`
}

// LoanContactSync represents a loan or debt contact.
type LoanContactSync struct {
	ID              uuid.UUID     `json:"id"`
	ContactName     string        `json:"contact_name"`
	Type            string        `json:"type"` // lend or borrow
	TotalAmount     float64       `json:"total_amount"`
	RemainingAmount float64       `json:"remaining_amount"`
	Status          string        `json:"status"`
	ClientCreatedAt FlexibleTime  `json:"created_at"`
	ClientUpdatedAt FlexibleTime  `json:"updated_at"`
	ServerUpdatedAt FlexibleTime  `json:"server_updated_at,omitempty"`
	DeletedAt       *FlexibleTime `json:"deleted_at,omitempty"`
}

// LoanTransactionSync represents a loan repayment installment transaction.
type LoanTransactionSync struct {
	ID              uuid.UUID     `json:"id"`
	LoanID          uuid.UUID     `json:"loan_id"`
	Amount          float64       `json:"amount"`
	Type            string        `json:"type"`
	Date            FlexibleTime  `json:"date"`
	DueDate         *string       `json:"due_date,omitempty"`
	Note            *string       `json:"note,omitempty"`
	ClientCreatedAt FlexibleTime  `json:"created_at"`
	ClientUpdatedAt FlexibleTime  `json:"updated_at"`
	ServerUpdatedAt FlexibleTime  `json:"server_updated_at,omitempty"`
	DeletedAt       *FlexibleTime `json:"deleted_at,omitempty"`
}

// RecurringConfigSync represents a recurring transaction schedule.
type RecurringConfigSync struct {
	ID              uuid.UUID     `json:"id"`
	CategoryID      *string       `json:"category_id,omitempty"`
	WalletID        *uuid.UUID    `json:"wallet_id,omitempty"`
	Name            string        `json:"name"`
	Amount          float64       `json:"amount"`
	Type            string        `json:"type"`
	Frequency       string        `json:"frequency"`
	Interval        int           `json:"interval"`
	DayOfWeek       *int          `json:"day_of_week,omitempty"`
	DayOfMonth      *int          `json:"day_of_month,omitempty"`
	NextRun         FlexibleTime  `json:"next_run"`
	IsActive        bool          `json:"is_active"`
	ClientCreatedAt FlexibleTime  `json:"created_at"`
	ClientUpdatedAt FlexibleTime  `json:"updated_at"`
	ServerUpdatedAt FlexibleTime  `json:"server_updated_at,omitempty"`
	DeletedAt       *FlexibleTime `json:"deleted_at,omitempty"`
}

// SyncRequest represents the full request payload for POST /api/v1/sync.
type SyncRequest struct {
	LastSyncedServerTime *FlexibleTime `json:"last_synced_server_time"`
	DeviceID             string        `json:"device_id"`
	Mutations            SyncMutations `json:"mutations"`
}

// SyncMutations groups all entity batches pushed by the client.
type SyncMutations struct {
	Wallets                []WalletSync                `json:"wallets"`
	WalletTransfers        []WalletTransferSync        `json:"wallet_transfers"`
	Categories             []CategorySync              `json:"categories"`
	Transactions           []TransactionSync           `json:"transactions"`
	MonthlyBudgets         []MonthlyBudgetSync         `json:"monthly_budgets"`
	CategoryMonthlyBudgets []CategoryMonthlyBudgetSync `json:"category_monthly_budgets"`
	SavingGoals            []SavingGoalSync            `json:"saving_goals"`
	SavingGoalLogs         []SavingGoalLogSync         `json:"saving_goal_logs"`
	LoanContacts           []LoanContactSync           `json:"loan_contacts"`
	LoanTransactions       []LoanTransactionSync       `json:"loan_transactions"`
	RecurringConfigs       []RecurringConfigSync       `json:"recurring_configs"`
	Deletions              []TombstoneDeletion         `json:"deletions"`
}

// SyncResponseData represents the data payload returned to client after sync.
type SyncResponseData struct {
	ServerTime time.Time   `json:"server_time"`
	Changes    SyncChanges `json:"changes"`
}

// SyncChanges groups all entity deltas returned to the client.
type SyncChanges struct {
	Wallets                []WalletSync                `json:"wallets"`
	WalletTransfers        []WalletTransferSync        `json:"wallet_transfers"`
	Categories             []CategorySync              `json:"categories"`
	Transactions           []TransactionSync           `json:"transactions"`
	MonthlyBudgets         []MonthlyBudgetSync         `json:"monthly_budgets"`
	CategoryMonthlyBudgets []CategoryMonthlyBudgetSync `json:"category_monthly_budgets"`
	SavingGoals            []SavingGoalSync            `json:"saving_goals"`
	SavingGoalLogs         []SavingGoalLogSync         `json:"saving_goal_logs"`
	LoanContacts           []LoanContactSync           `json:"loan_contacts"`
	LoanTransactions       []LoanTransactionSync       `json:"loan_transactions"`
	RecurringConfigs       []RecurringConfigSync       `json:"recurring_configs"`
	Deletions              []TombstoneDeletion         `json:"deletions"`
}
