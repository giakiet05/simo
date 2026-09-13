import { api, getAuthToken } from './api';
import { localDb, recalculateWalletBalances } from './db';
import type {
  SyncStatus,
  LiveStreamStatus,
  ServerSyncMutations,
  Wallet,
  WalletTransfer,
  Category,
  Transaction,
  MonthlyBudget,
  CategoryMonthlyBudget,
  SavingGoal,
  SavingGoalLog,
  LoanContact,
  LoanTransaction,
  RecurringConfig,
} from '../types';

type SyncListener = (status: SyncStatus) => void;

class SyncService {
  private isSyncing = false;
  private streamStatus: LiveStreamStatus = 'disconnected';
  private debounceTimer: number | null = null;
  private listeners: Set<SyncListener> = new Set();
  private lastError: string | null = null;

  public updateStreamStatus(status: LiveStreamStatus) {
    this.streamStatus = status;
    this.notify();
  }

  public getStatus(): SyncStatus {
    const unsynced = localDb.getUnsyncedServerMutations();
    const pendingCount =
      unsynced.wallets.length +
      unsynced.wallet_transfers.length +
      unsynced.categories.length +
      unsynced.transactions.length +
      unsynced.monthly_budgets.length +
      unsynced.category_monthly_budgets.length +
      unsynced.saving_goals.length +
      unsynced.saving_goal_logs.length +
      unsynced.loan_contacts.length +
      unsynced.loan_transactions.length +
      unsynced.recurring_configs.length +
      unsynced.deletions.length;

    return {
      isSyncing: this.isSyncing,
      streamStatus: this.streamStatus,
      lastSyncedTime: localDb.getLastSyncedTime(),
      pendingCount,
      error: this.lastError,
    };
  }

  public subscribe(listener: SyncListener): () => void {
    this.listeners.add(listener);
    listener(this.getStatus());
    return () => this.listeners.delete(listener);
  }

  private notify() {
    const status = this.getStatus();
    this.listeners.forEach((l) => l(status));
  }

  public triggerDebouncedSync(delayMs = 800) {
    if (this.debounceTimer) {
      clearTimeout(this.debounceTimer);
    }
    this.debounceTimer = window.setTimeout(() => {
      this.syncNow().catch((err) => console.warn('Background sync error:', err));
    }, delayMs);
  }

  public async syncNow(): Promise<boolean> {
    if (this.isSyncing) return false;
    const token = getAuthToken();
    if (!token) {
      this.lastError = null;
      this.notify();
      return false; // Local-only mode when unauthenticated
    }

    this.isSyncing = true;
    this.lastError = null;
    this.notify();

    try {
      const lastSyncedTime = localDb.getLastSyncedTime() || undefined;
      const deviceId = localDb.getDeviceId();
      const mutations = localDb.getUnsyncedServerMutations();

      const response = await api.sync({
        last_synced_server_time: lastSyncedTime,
        device_id: deviceId,
        mutations,
      });

      const { server_time, changes } = response;
      this.applyServerChanges(changes);
      localDb.markSynced(server_time);

      this.isSyncing = false;
      this.lastError = null;
      this.notify();
      return true;
    } catch (err: any) {
      this.isSyncing = false;
      this.lastError = err.message || 'Sync failed';
      this.notify();
      throw err;
    }
  }

  private applyServerChanges(changes: ServerSyncMutations) {
    const state = localDb.loadState();

    const mergeEntityList = <T extends { id: string }>(
      existingList: T[],
      incomingList: T[]
    ): T[] => {
      if (!incomingList || incomingList.length === 0) return existingList;
      const map = new Map<string, T>();
      existingList.forEach((item) => map.set(item.id, item));
      incomingList.forEach((item) => map.set(item.id, item));
      return Array.from(map.values());
    };

    const applyDeletions = <T extends { id: string }>(
      items: T[],
      tableName: string
    ): T[] => {
      const deletedIds = new Set(
        (changes.deletions || [])
          .filter((d) => d.table_name === tableName)
          .map((d) => d.id)
      );
      if (deletedIds.size === 0) return items;
      return items.filter((item) => !deletedIds.has(item.id));
    };

    // 1. Wallets
    const incomingWallets: Wallet[] = (changes.wallets || []).map((w) => ({
      id: w.id,
      cloud_id: w.id,
      name: w.name,
      type: w.type as any,
      initial_balance: w.initial_balance,
      balance: w.initial_balance,
      currency: w.currency || 'VND',
      icon: w.icon || 'wallet',
      color: w.color || '#10B981',
      is_default: Boolean(w.is_default),
      exclude_from_total: Boolean(w.exclude_from_total),
      priority: w.priority || 0,
      synced: 1,
      created_at: w.created_at,
      updated_at: w.updated_at,
    }));
    state.wallets = applyDeletions(mergeEntityList(state.wallets, incomingWallets), 'wallets');

    // 2. Categories
    const incomingCategories: Category[] = (changes.categories || []).map((c) => ({
      id: c.id,
      cloud_id: c.id,
      name: c.name,
      type: c.type as any,
      icon: c.icon || 'tag',
      color: c.color || '#3B82F6',
      budget_limit: c.budget_limit,
      synced: 1,
      created_at: c.created_at,
      updated_at: c.updated_at,
    }));
    state.categories = applyDeletions(mergeEntityList(state.categories, incomingCategories), 'categories');

    // 3. Transactions
    const incomingTransactions: Transaction[] = (changes.transactions || []).map((t) => ({
      id: t.id,
      cloud_id: t.id,
      wallet_id: t.wallet_id,
      category_id: t.category_id,
      recurring_config_id: t.recurring_config_id,
      type: t.type as any,
      amount: t.amount,
      formula: t.formula,
      note: t.note,
      date: t.transaction_date,
      transaction_date: t.transaction_date,
      synced: 1,
      created_at: t.created_at,
      updated_at: t.updated_at,
    }));
    state.transactions = applyDeletions(mergeEntityList(state.transactions, incomingTransactions), 'transactions');

    // 4. Wallet Transfers
    const incomingTransfers: WalletTransfer[] = (changes.wallet_transfers || []).map((wt) => ({
      id: wt.id,
      cloud_id: wt.id,
      from_wallet_id: wt.source_wallet_id,
      to_wallet_id: wt.destination_wallet_id,
      source_wallet_id: wt.source_wallet_id,
      destination_wallet_id: wt.destination_wallet_id,
      amount: wt.amount,
      fee: wt.fee || 0,
      date: wt.transfer_date,
      transfer_date: wt.transfer_date,
      note: wt.note,
      synced: 1,
      created_at: wt.created_at,
      updated_at: wt.updated_at,
    }));
    state.wallet_transfers = applyDeletions(mergeEntityList(state.wallet_transfers, incomingTransfers), 'wallet_transfers');

    // 5. Monthly Budgets
    const incomingBudgets: MonthlyBudget[] = (changes.monthly_budgets || []).map((mb) => ({
      id: mb.id,
      cloud_id: mb.id,
      year: mb.year,
      month: mb.month,
      amount: mb.amount,
      synced: 1,
      created_at: mb.created_at,
      updated_at: mb.updated_at,
    }));
    state.monthly_budgets = applyDeletions(mergeEntityList(state.monthly_budgets, incomingBudgets), 'monthly_budgets');

    // 6. Category Monthly Budgets
    const incomingCatBudgets: CategoryMonthlyBudget[] = (changes.category_monthly_budgets || []).map((cmb) => ({
      id: cmb.id,
      cloud_id: cmb.id,
      category_id: cmb.category_id,
      year: cmb.year,
      month: cmb.month,
      amount: cmb.amount,
      synced: 1,
      created_at: cmb.created_at,
      updated_at: cmb.updated_at,
    }));
    state.category_monthly_budgets = applyDeletions(
      mergeEntityList(state.category_monthly_budgets, incomingCatBudgets),
      'category_monthly_budgets'
    );

    // 7. Saving Goals
    const incomingGoals: SavingGoal[] = (changes.saving_goals || []).map((sg) => ({
      id: sg.id,
      cloud_id: sg.id,
      name: sg.name,
      target_amount: sg.target_amount,
      current_amount: sg.current_amount || 0,
      target_date: sg.target_date,
      icon: sg.icon || 'target',
      color: sg.color || '#10B981',
      note: sg.note,
      status: sg.status || 'active',
      synced: 1,
      created_at: sg.created_at,
      updated_at: sg.updated_at,
    }));
    state.saving_goals = applyDeletions(mergeEntityList(state.saving_goals, incomingGoals), 'saving_goals');

    // 8. Saving Goal Logs
    const incomingGoalLogs: SavingGoalLog[] = (changes.saving_goal_logs || []).map((sgl) => ({
      id: sgl.id,
      cloud_id: sgl.id,
      goal_id: sgl.goal_id,
      amount: sgl.amount,
      type: sgl.type as any,
      date: sgl.log_date,
      log_date: sgl.log_date,
      note: sgl.note,
      synced: 1,
      created_at: sgl.created_at,
      updated_at: sgl.updated_at,
    }));
    state.saving_goal_logs = applyDeletions(mergeEntityList(state.saving_goal_logs, incomingGoalLogs), 'saving_goal_logs');

    // 9. Loan Contacts
    const incomingLoans: LoanContact[] = (changes.loan_contacts || []).map((lc) => ({
      id: lc.id,
      cloud_id: lc.id,
      name: lc.contact_name,
      contact_name: lc.contact_name,
      type: lc.type as any,
      total_amount: lc.total_amount,
      remaining_amount: lc.remaining_amount,
      status: lc.status || 'active',
      synced: 1,
      created_at: lc.created_at,
      updated_at: lc.updated_at,
    }));
    state.loan_contacts = applyDeletions(mergeEntityList(state.loan_contacts, incomingLoans), 'loan_contacts');

    // 10. Loan Transactions
    const incomingLoanTxs: LoanTransaction[] = (changes.loan_transactions || []).map((lt) => ({
      id: lt.id,
      cloud_id: lt.id,
      contact_id: lt.loan_id,
      loan_id: lt.loan_id,
      amount: lt.amount,
      type: lt.type as any,
      date: lt.date,
      due_date: lt.due_date,
      note: lt.note,
      synced: 1,
      created_at: lt.created_at,
      updated_at: lt.updated_at,
    }));
    state.loan_transactions = applyDeletions(mergeEntityList(state.loan_transactions, incomingLoanTxs), 'loan_transactions');

    // 11. Recurring Configs
    const incomingRecurrings: RecurringConfig[] = (changes.recurring_configs || []).map((rc) => ({
      id: rc.id,
      cloud_id: rc.id,
      category_id: rc.category_id,
      wallet_id: rc.wallet_id,
      name: rc.name,
      amount: rc.amount,
      type: rc.type as any,
      frequency: rc.frequency as any,
      interval: rc.interval || 1,
      day_of_week: rc.day_of_week,
      day_of_month: rc.day_of_month,
      next_run: rc.next_run,
      next_run_date: rc.next_run,
      is_active: Boolean(rc.is_active),
      synced: 1,
      created_at: rc.created_at,
      updated_at: rc.updated_at,
    }));
    state.recurring_configs = applyDeletions(mergeEntityList(state.recurring_configs, incomingRecurrings), 'recurring_configs');

    // Recalculate wallet balances and persist to localStorage
    const finalState = recalculateWalletBalances(state);
    localDb.saveAll(finalState);
  }
}

export const syncService = new SyncService();
