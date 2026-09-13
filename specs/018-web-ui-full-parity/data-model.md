# Data Model: Web UI Full Feature Parity

**Feature**: `018-web-ui-full-parity`
**Date**: 2026-09-13

This document defines the 11 core financial entities, client-side store schemas, and pending deletion tombstone tracking implemented in the Web UI, maintaining 100% schema parity with the Android SQLite database and the Go server PostgreSQL schema.

---

## 1. Entities & Field Definitions

### 1.1 `Wallet`
Represents a financial account or payment source.
- `id` (string / UUID): Local identifier.
- `cloud_id` (string / UUID): Global sync identifier.
- `name` (string): Wallet name (e.g., "Ví Tiền Mặt", "Techcombank", "Thẻ Tín Dụng").
- `balance` (number): Current balance.
- `currency` (string): 3-letter currency code (e.g., "VND", "USD").
- `type` (string): `cash` | `bank` | `credit` | `ewallet` | `savings`.
- `icon` (string): Icon identifier name.
- `color` (string): Hex color code (e.g., "#10B981").
- `is_default` (boolean): Whether this is the default wallet.
- `exclude_from_total` (boolean): Whether this wallet balance is excluded from Total Net Worth.
- `credit_limit` (number, optional): Max credit limit for credit card accounts.
- `synced` (number): `0` = pending sync, `1` = synchronized.
- `updated_at` (string, ISO 8601): Last update timestamp.

---

### 1.2 `WalletTransfer`
Represents an inter-wallet transfer of funds.
- `id` (string / UUID): Local identifier.
- `cloud_id` (string / UUID): Global sync identifier.
- `from_wallet_id` (string / UUID): Source wallet `cloud_id`.
- `to_wallet_id` (string / UUID): Destination wallet `cloud_id`.
- `amount` (number): Transfer amount.
- `fee` (number): Transfer fee.
- `date` (string, ISO 8601 / YYYY-MM-DD): Date of transfer.
- `note` (string, optional): Description or reference note.
- `synced` (number): `0` | `1`.
- `updated_at` (string, ISO 8601).

---

### 1.3 `Category`
Represents a classification for income or expense.
- `id` (string / UUID): Local identifier.
- `cloud_id` (string / UUID): Global sync identifier.
- `name` (string): Category name (e.g., "Ăn uống", "Lương", "Di chuyển").
- `icon` (string): Icon name.
- `color` (string): Hex color code.
- `type` (string): `expense` | `income`.
- `parent_id` (string / UUID, optional): Parent category `cloud_id` for hierarchical nesting.
- `synced` (number): `0` | `1`.
- `updated_at` (string, ISO 8601).

---

### 1.4 `Transaction`
Represents a single financial inflow, outflow, or adjustment.
- `id` (string / UUID): Local identifier.
- `cloud_id` (string / UUID): Global sync identifier.
- `wallet_id` (string / UUID): Associated wallet `cloud_id`.
- `category_id` (string / UUID, optional): Associated category `cloud_id`.
- `type` (string): `expense` | `income` | `transfer` | `loan`.
- `amount` (number): Transaction monetary amount.
- `date` (string, ISO 8601): Date and time of transaction.
- `note` (string, optional): Description or memo.
- `image_url` (string, optional): Attached receipt image path or URL.
- `synced` (number): `0` | `1`.
- `updated_at` (string, ISO 8601).

---

### 1.5 `MonthlyBudget`
Represents an overall monthly spending ceiling.
- `id` (string / UUID): Local identifier.
- `cloud_id` (string / UUID): Global sync identifier.
- `month` (number): 1-12.
- `year` (number): Full 4-digit year (e.g., 2026).
- `amount` (number): Maximum overall expense limit for the month.
- `synced` (number): `0` | `1`.
- `updated_at` (string, ISO 8601).

---

### 1.6 `CategoryMonthlyBudget`
Represents a budget cap for a specific category within a month.
- `id` (string / UUID): Local identifier.
- `cloud_id` (string / UUID): Global sync identifier.
- `category_id` (string / UUID): Category `cloud_id`.
- `month` (number): 1-12.
- `year` (number): Full 4-digit year.
- `amount` (number): Maximum budget for this category in the month.
- `synced` (number): `0` | `1`.
- `updated_at` (string, ISO 8601).

---

### 1.7 `SavingGoal`
Represents a long-term or short-term financial target.
- `id` (string / UUID): Local identifier.
- `cloud_id` (string / UUID): Global sync identifier.
- `name` (string): Goal name (e.g., "Quỹ Khẩn Cấp", "Mua Laptop").
- `target_amount` (number): Target monetary amount.
- `current_amount` (number): Accumulated funds.
- `target_date` (string, YYYY-MM-DD): Target completion date.
- `icon` (string): Icon name.
- `color` (string): Hex color code.
- `synced` (number): `0` | `1`.
- `updated_at` (string, ISO 8601).

---

### 1.8 `SavingGoalLog`
Represents a deposit or withdrawal event towards a saving goal.
- `id` (string / UUID): Local identifier.
- `cloud_id` (string / UUID): Global sync identifier.
- `goal_id` (string / UUID): Goal `cloud_id`.
- `wallet_id` (string / UUID): Wallet `cloud_id` funding or receiving the amount.
- `amount` (number): Deposit or withdrawal amount.
- `type` (string): `deposit` | `withdraw`.
- `date` (string, ISO 8601): Log timestamp.
- `note` (string, optional): Log note.
- `synced` (number): `0` | `1`.
- `updated_at` (string, ISO 8601).

---

### 1.9 `LoanContact`
Represents an individual or entity involved in personal loans.
- `id` (string / UUID): Local identifier.
- `cloud_id` (string / UUID): Global sync identifier.
- `name` (string): Contact name.
- `phone` (string, optional): Contact phone number.
- `note` (string, optional): Description or relationship note.
- `synced` (number): `0` | `1`.
- `updated_at` (string, ISO 8601).

---

### 1.10 `LoanTransaction`
Represents a loan creation (borrow/lend) or repayment event.
- `id` (string / UUID): Local identifier.
- `cloud_id` (string / UUID): Global sync identifier.
- `contact_id` (string / UUID): Loan contact `cloud_id`.
- `wallet_id` (string / UUID): Linked wallet `cloud_id`.
- `type` (string): `lend` (cho vay) | `borrow` (vay) | `repayment_received` (thu nợ) | `repayment_paid` (trả nợ).
- `amount` (number): Transaction amount.
- `date` (string, ISO 8601): Event timestamp.
- `note` (string, optional): Note or memo.
- `synced` (number): `0` | `1`.
- `updated_at` (string, ISO 8601).

---

### 1.11 `RecurringConfig`
Represents an automated or scheduled financial transaction.
- `id` (string / UUID): Local identifier.
- `cloud_id` (string / UUID): Global sync identifier.
- `frequency` (string): `daily` | `weekly` | `monthly` | `yearly`.
- `amount` (number): Amount.
- `category_id` (string / UUID): Category `cloud_id`.
- `wallet_id` (string / UUID): Wallet `cloud_id`.
- `start_date` (string, YYYY-MM-DD): Start date.
- `end_date` (string, YYYY-MM-DD, optional): Expiration date.
- `next_run_date` (string, YYYY-MM-DD): Next due execution date.
- `note` (string, optional): Description.
- `synced` (number): `0` | `1`.
- `updated_at` (string, ISO 8601).

---

### 1.12 `PendingDeletion` (Tombstone Record)
Tracks entities deleted locally so the sync engine can push deletion tombstones to the server.
- `id` (string / UUID): Local identifier.
- `cloud_id` (string / UUID): Deleted record's global `cloud_id`.
- `table_name` (string): Table name of the deleted entity.
- `deleted_at` (string, ISO 8601): Deletion timestamp.

---

## 2. Client Store State & Relationships

```
                  ┌─────────────────────────────────┐
                  │          UserProfile            │
                  │   (Theme, Currency, Locale)     │
                  └─────────────────────────────────┘
                                   │
      ┌────────────────────────────┼────────────────────────────┐
      ▼                            ▼                            ▼
┌───────────┐                ┌───────────┐                ┌───────────┐
│  Wallet   │                │ Category  │                │LoanContact│
└─────┬─────┘                └─────┬─────┘                └─────┬─────┘
      │ 1                          │ 1                          │ 1
      │                            │                            │
      │ *                          │ *                          │ *
┌─────┴────────────────────────────┴─────┐                ┌─────┴───────────┐
│             Transaction                │                │ LoanTransaction │
│ (Expense / Income / Transfer / Loan)   │                └─────────────────┘
└────────────────────────────────────────┘
      ▲                            ▲
      │ 1                          │ 1
      │ *                          │ *
┌─────┴─────────────┐        ┌─────┴────────────────────┐
│  SavingGoalLog    │        │  CategoryMonthlyBudget   │
│         ▲         │        └──────────────────────────┘
│         │ *       │
│   ┌─────┴──────┐  │
│   │ SavingGoal │  │
│   └────────────┘  │
└───────────────────┘
```
