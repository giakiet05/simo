# Interface Contracts: Web UI Full Feature Parity

**Feature**: `018-web-ui-full-parity`
**Date**: 2026-09-13

This document specifies the TypeScript client-side service contracts, API integration endpoints, and sync payload schemas for the Web UI.

---

## 1. REST API Endpoints

### 1.1 Authentication & Profile
- `POST /api/auth/google`: Authenticate with Google OAuth ID token.
  - **Request**: `{ id_token: string }`
  - **Response**: `{ message: string, token: string, user: { id: string, email: string, name: string, avatar_url: string } }`
- `GET /api/auth/me`: Get current authenticated user session.
  - **Headers**: `Authorization: Bearer <token>`
  - **Response**: `{ user: UserProfile }`

### 1.2 Synchronization Engine
- `POST /api/sync`: Bidirectional incremental sync endpoint.
  - **Headers**: `Authorization: Bearer <token>`
  - **Request Payload**:
    ```json
    {
      "last_synced_server_time": "2026-09-13T12:00:00Z",
      "device_id": "web-browser-uuid",
      "mutations": {
        "wallets": [Wallet],
        "wallet_transfers": [WalletTransfer],
        "categories": [Category],
        "transactions": [Transaction],
        "monthly_budgets": [MonthlyBudget],
        "category_monthly_budgets": [CategoryMonthlyBudget],
        "saving_goals": [SavingGoal],
        "saving_goal_logs": [SavingGoalLog],
        "loan_contacts": [LoanContact],
        "loan_transactions": [LoanTransaction],
        "recurring_configs": [RecurringConfig],
        "deletions": [
          {
            "cloud_id": "uuid",
            "table_name": "transactions",
            "deleted_at": "2026-09-13T12:05:00Z"
          }
        ]
      }
    }
    ```
  - **Response Payload**:
    ```json
    {
      "message": "Sync completed successfully",
      "data": {
        "server_time": "2026-09-13T12:10:00Z",
        "changes": {
          "wallets": [Wallet],
          "wallet_transfers": [WalletTransfer],
          "categories": [Category],
          "transactions": [Transaction],
          "monthly_budgets": [MonthlyBudget],
          "category_monthly_budgets": [CategoryMonthlyBudget],
          "saving_goals": [SavingGoal],
          "saving_goal_logs": [SavingGoalLog],
          "loan_contacts": [LoanContact],
          "loan_transactions": [LoanTransaction],
          "recurring_configs": [RecurringConfig],
          "deletions": [PendingDeletion]
        }
      }
    }
    ```

---

## 2. Client-Side Service Interfaces

### 2.1 `ISyncService`
```typescript
export interface ISyncService {
  syncNow(): Promise<SyncResult>;
  triggerDebouncedSync(): void;
  getSyncStatus(): SyncStatus;
  onSyncStatusChange(callback: (status: SyncStatus) => void): () => void;
}
```

### 2.2 `IFinanceStore`
```typescript
export interface IFinanceStore {
  // Wallets
  getWallets(): Wallet[];
  createWallet(wallet: Omit<Wallet, 'id' | 'cloud_id' | 'synced' | 'updated_at'>): Promise<Wallet>;
  updateWallet(id: string, updates: Partial<Wallet>): Promise<void>;
  deleteWallet(id: string): Promise<void>;
  transferFunds(transfer: Omit<WalletTransfer, 'id' | 'cloud_id' | 'synced' | 'updated_at'>): Promise<void>;

  // Transactions
  getTransactions(filter?: TransactionFilterCriteria): Transaction[];
  createTransaction(tx: Omit<Transaction, 'id' | 'cloud_id' | 'synced' | 'updated_at'>): Promise<Transaction>;
  updateTransaction(id: string, updates: Partial<Transaction>): Promise<void>;
  deleteTransaction(id: string): Promise<void>;
  bulkDeleteTransactions(ids: string[]): Promise<void>;
  bulkUpdateCategory(ids: string[], categoryId: string): Promise<void>;
  bulkUpdateDate(ids: string[], newDate: string): Promise<void>;

  // Categories
  getCategories(type?: 'expense' | 'income'): Category[];
  createCategory(category: Omit<Category, 'id' | 'cloud_id' | 'synced' | 'updated_at'>): Promise<Category>;
  updateCategory(id: string, updates: Partial<Category>): Promise<void>;
  deleteCategory(id: string): Promise<void>;

  // Budgets
  getMonthlyBudget(month: number, year: number): MonthlyBudget | null;
  setMonthlyBudget(month: number, year: number, amount: number): Promise<void>;
  getCategoryBudgets(month: number, year: number): CategoryMonthlyBudget[];
  setCategoryBudget(categoryId: string, month: number, year: number, amount: number): Promise<void>;

  // Saving Goals
  getSavingGoals(): SavingGoal[];
  createSavingGoal(goal: Omit<SavingGoal, 'id' | 'cloud_id' | 'synced' | 'updated_at'>): Promise<SavingGoal>;
  updateSavingGoal(id: string, updates: Partial<SavingGoal>): Promise<void>;
  deleteSavingGoal(id: string): Promise<void>;
  depositToGoal(goalId: string, walletId: string, amount: number, note?: string): Promise<void>;
  withdrawFromGoal(goalId: string, walletId: string, amount: number, note?: string): Promise<void>;

  // Loans & Debts
  getLoanContacts(): LoanContact[];
  createLoanContact(contact: Omit<LoanContact, 'id' | 'cloud_id' | 'synced' | 'updated_at'>): Promise<LoanContact>;
  createLoanTransaction(tx: Omit<LoanTransaction, 'id' | 'cloud_id' | 'synced' | 'updated_at'>): Promise<LoanTransaction>;

  // Recurring
  getRecurringConfigs(): RecurringConfig[];
  createRecurringConfig(config: Omit<RecurringConfig, 'id' | 'cloud_id' | 'synced' | 'updated_at'>): Promise<RecurringConfig>;
  updateRecurringConfig(id: string, updates: Partial<RecurringConfig>): Promise<void>;
  deleteRecurringConfig(id: string): Promise<void>;
}
```

---

## 3. UI Theme Token Contracts

```css
:root {
  /* Light Theme Defaults (Crisp White) */
  --bg-app: #ffffff;
  --bg-surface: #f8fafc;
  --bg-card: #ffffff;
  --border-subtle: #e2e8f0;
  --text-primary: #0f172a;
  --text-secondary: #64748b;
  --color-brand: #0d9488;
  --color-income: #10b981;
  --color-expense: #f43f5e;
}

[data-theme='dark'] {
  /* Dark Theme Overrides */
  --bg-app: #020617;
  --bg-surface: #0f172a;
  --bg-card: #0f172a;
  --border-subtle: #1e293b;
  --text-primary: #f8fafc;
  --text-secondary: #94a3b8;
  --color-brand: #14b8a6;
  --color-income: #34d399;
  --color-expense: #fb7185;
}
```
