/**
 * Core Domain Models and Type Definitions for Simo Web Application.
 * Full 1:1 parity with SQLite local models and server PostgreSQL schema.
 */

export type TransactionType = 'expense' | 'income' | 'transfer' | 'loan';
export type CategoryType = 'expense' | 'income';
export type WalletType = 'cash' | 'bank' | 'credit' | 'ewallet' | 'savings';
export type SavingGoalLogType = 'deposit' | 'withdraw';
export type LoanType = 'lend' | 'borrow' | 'repayment_received' | 'repayment_paid';
export type RecurringFrequency = 'daily' | 'weekly' | 'monthly' | 'yearly';
export type ThemeMode = 'light' | 'dark' | 'system';

export interface UserProfile {
  id: string;
  email: string;
  display_name: string | null;
  avatar_url: string | null;
  created_at?: string;
}

export interface Wallet {
  id: string;
  cloud_id: string;
  name: string;
  type: WalletType;
  initial_balance?: number;
  balance: number;
  currency: string;
  icon: string;
  color: string;
  is_default: boolean;
  exclude_from_total: boolean;
  priority?: number;
  credit_limit?: number;
  synced: number;
  created_at?: string;
  updated_at: string;
}

export interface WalletTransfer {
  id: string;
  cloud_id: string;
  from_wallet_id: string;
  to_wallet_id: string;
  source_wallet_id?: string;
  destination_wallet_id?: string;
  amount: number;
  fee: number;
  date: string;
  transfer_date?: string;
  note?: string;
  synced: number;
  created_at?: string;
  updated_at: string;
}

export interface Category {
  id: string;
  cloud_id: string;
  name: string;
  icon: string;
  color: string;
  type: CategoryType;
  budget_limit?: number;
  parent_id?: string;
  synced: number;
  created_at?: string;
  updated_at: string;
}

export interface Transaction {
  id: string;
  cloud_id: string;
  wallet_id?: string;
  category_id?: string;
  recurring_config_id?: string;
  type: TransactionType;
  amount: number;
  formula?: string;
  date: string;
  transaction_date?: string;
  note?: string;
  image_url?: string;
  synced: number;
  created_at?: string;
  updated_at: string;
}

export interface MonthlyBudget {
  id: string;
  cloud_id: string;
  month: number;
  year: number;
  amount: number;
  synced: number;
  created_at?: string;
  updated_at: string;
}

export interface CategoryMonthlyBudget {
  id: string;
  cloud_id: string;
  category_id: string;
  month: number;
  year: number;
  amount: number;
  synced: number;
  created_at?: string;
  updated_at: string;
}

export interface SavingGoal {
  id: string;
  cloud_id: string;
  name: string;
  target_amount: number;
  current_amount: number;
  target_date?: string;
  icon?: string;
  color?: string;
  note?: string;
  status?: string;
  synced: number;
  created_at?: string;
  updated_at: string;
}

export interface SavingGoalLog {
  id: string;
  cloud_id: string;
  goal_id: string;
  wallet_id?: string;
  amount: number;
  type: SavingGoalLogType;
  date: string;
  log_date?: string;
  note?: string;
  synced: number;
  created_at?: string;
  updated_at?: string;
}

export interface LoanContact {
  id: string;
  cloud_id: string;
  name: string;
  contact_name?: string;
  type?: LoanType;
  total_amount?: number;
  remaining_amount?: number;
  status?: string;
  phone?: string;
  note?: string;
  synced: number;
  created_at?: string;
  updated_at: string;
}

export interface LoanTransaction {
  id: string;
  cloud_id: string;
  contact_id: string;
  loan_id?: string;
  wallet_id?: string;
  type: LoanType;
  amount: number;
  date: string;
  due_date?: string;
  note?: string;
  synced: number;
  created_at?: string;
  updated_at: string;
}

export interface RecurringConfig {
  id: string;
  cloud_id: string;
  name?: string;
  amount: number;
  type?: TransactionType;
  frequency: RecurringFrequency;
  interval?: number;
  day_of_week?: number;
  day_of_month?: number;
  category_id?: string;
  wallet_id?: string;
  start_date?: string;
  end_date?: string;
  next_run?: string;
  next_run_date: string;
  note?: string;
  is_active?: boolean;
  synced: number;
  created_at?: string;
  updated_at: string;
}

export interface PendingDeletion {
  id: string;
  cloud_id?: string;
  table_name: string;
  deleted_at: string;
}

export interface LocalDatabaseState {
  wallets: Wallet[];
  wallet_transfers: WalletTransfer[];
  categories: Category[];
  transactions: Transaction[];
  monthly_budgets: MonthlyBudget[];
  category_monthly_budgets: CategoryMonthlyBudget[];
  saving_goals: SavingGoal[];
  saving_goal_logs: SavingGoalLog[];
  loan_contacts: LoanContact[];
  loan_transactions: LoanTransaction[];
  recurring_configs: RecurringConfig[];
  deletions: PendingDeletion[];
}

// Raw JSON shapes exchanged with Go Server /api/v1/sync
export interface ServerWalletSync {
  id: string;
  name: string;
  type: string;
  initial_balance: number;
  color: string;
  icon: string;
  currency?: string;
  is_default: boolean;
  exclude_from_total: boolean;
  priority: number;
  created_at: string;
  updated_at: string;
  server_updated_at?: string;
  deleted_at?: string;
}

export interface ServerCategorySync {
  id: string;
  name: string;
  type: string;
  icon?: string;
  color?: string;
  budget_limit?: number;
  created_at: string;
  updated_at: string;
  server_updated_at?: string;
  deleted_at?: string;
}

export interface ServerTransactionSync {
  id: string;
  wallet_id?: string;
  category_id?: string;
  recurring_config_id?: string;
  amount: number;
  formula?: string;
  note?: string;
  type: string;
  transaction_date: string;
  created_at: string;
  updated_at: string;
  server_updated_at?: string;
  deleted_at?: string;
}

export interface ServerWalletTransferSync {
  id: string;
  source_wallet_id: string;
  destination_wallet_id: string;
  amount: number;
  fee: number;
  transfer_date: string;
  note?: string;
  created_at: string;
  updated_at: string;
  server_updated_at?: string;
  deleted_at?: string;
}

export interface ServerMonthlyBudgetSync {
  id: string;
  year: number;
  month: number;
  amount: number;
  created_at: string;
  updated_at: string;
  server_updated_at?: string;
  deleted_at?: string;
}

export interface ServerCategoryMonthlyBudgetSync {
  id: string;
  category_id: string;
  year: number;
  month: number;
  amount: number;
  created_at: string;
  updated_at: string;
  server_updated_at?: string;
  deleted_at?: string;
}

export interface ServerSavingGoalSync {
  id: string;
  name: string;
  target_amount: number;
  current_amount: number;
  target_date?: string;
  color?: string;
  icon?: string;
  note?: string;
  status: string;
  created_at: string;
  updated_at: string;
  server_updated_at?: string;
  deleted_at?: string;
}

export interface ServerSavingGoalLogSync {
  id: string;
  goal_id: string;
  amount: number;
  type: string;
  log_date: string;
  note?: string;
  created_at: string;
  updated_at?: string;
  server_updated_at?: string;
  deleted_at?: string;
}

export interface ServerLoanContactSync {
  id: string;
  contact_name: string;
  type: string;
  total_amount: number;
  remaining_amount: number;
  status: string;
  created_at: string;
  updated_at: string;
  server_updated_at?: string;
  deleted_at?: string;
}

export interface ServerLoanTransactionSync {
  id: string;
  loan_id: string;
  amount: number;
  type: string;
  date: string;
  due_date?: string;
  note?: string;
  created_at: string;
  updated_at: string;
  server_updated_at?: string;
  deleted_at?: string;
}

export interface ServerRecurringConfigSync {
  id: string;
  category_id?: string;
  wallet_id?: string;
  name: string;
  amount: number;
  type: string;
  frequency: string;
  interval: number;
  day_of_week?: number;
  day_of_month?: number;
  next_run: string;
  is_active: boolean;
  created_at: string;
  updated_at: string;
  server_updated_at?: string;
  deleted_at?: string;
}

export interface ServerTombstoneDeletion {
  table_name: string;
  id: string;
  deleted_at: string;
}

export interface ServerSyncMutations {
  wallets: ServerWalletSync[];
  wallet_transfers: ServerWalletTransferSync[];
  categories: ServerCategorySync[];
  transactions: ServerTransactionSync[];
  monthly_budgets: ServerMonthlyBudgetSync[];
  category_monthly_budgets: ServerCategoryMonthlyBudgetSync[];
  saving_goals: ServerSavingGoalSync[];
  saving_goal_logs: ServerSavingGoalLogSync[];
  loan_contacts: ServerLoanContactSync[];
  loan_transactions: ServerLoanTransactionSync[];
  recurring_configs: ServerRecurringConfigSync[];
  deletions: ServerTombstoneDeletion[];
}

export interface SyncRequestBody {
  last_synced_server_time?: string;
  device_id: string;
  mutations: ServerSyncMutations;
}

export interface SyncResponseData {
  server_time: string;
  changes: ServerSyncMutations;
}

export interface TransactionFilterCriteria {
  startDate?: string;
  endDate?: string;
  walletId?: string;
  categoryIds?: string[];
  type?: TransactionType | 'all';
  minAmount?: number;
  maxAmount?: number;
  keyword?: string;
}

export type LiveStreamStatus = 'connected' | 'connecting' | 'reconnecting' | 'disconnected';

export interface SyncStatus {
  isSyncing: boolean;
  streamStatus: LiveStreamStatus;
  lastSyncedTime: string | null;
  pendingCount: number;
  error: string | null;
}
