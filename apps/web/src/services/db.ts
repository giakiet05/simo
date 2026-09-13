import type {
  PendingDeletion,
  LocalDatabaseState,
  ServerSyncMutations,
} from '../types';

const DB_PREFIX = 'simo_db_';

export function generateUUID(): string {
  if (typeof crypto !== 'undefined' && crypto.randomUUID) {
    return crypto.randomUUID();
  }
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}

export const getInitialDBState = (): LocalDatabaseState => ({
  wallets: [],
  wallet_transfers: [],
  categories: [],
  transactions: [],
  monthly_budgets: [],
  category_monthly_budgets: [],
  saving_goals: [],
  saving_goal_logs: [],
  loan_contacts: [],
  loan_transactions: [],
  recurring_configs: [],
  deletions: [],
});

export function recalculateWalletBalances(state: LocalDatabaseState): LocalDatabaseState {
  const wallets = state.wallets.map((w) => {
    const walletId = w.id || w.cloud_id;
    const initialBalance = Number(w.initial_balance ?? w.balance ?? 0);

    const totalIncome = state.transactions
      .filter((t) => (t.wallet_id === walletId) && t.type === 'income')
      .reduce((sum, t) => sum + (Number(t.amount) || 0), 0);

    const totalExpense = state.transactions
      .filter((t) => (t.wallet_id === walletId) && t.type === 'expense')
      .reduce((sum, t) => sum + (Number(t.amount) || 0), 0);

    const totalTransferIn = state.wallet_transfers
      .filter((wt) => (wt.destination_wallet_id === walletId || wt.to_wallet_id === walletId))
      .reduce((sum, wt) => sum + (Number(wt.amount) || 0), 0);

    const totalTransferOut = state.wallet_transfers
      .filter((wt) => (wt.source_wallet_id === walletId || wt.from_wallet_id === walletId))
      .reduce((sum, wt) => sum + (Number(wt.amount) || 0) + (Number(wt.fee) || 0), 0);

    const calculatedBalance = initialBalance + totalIncome - totalExpense + totalTransferIn - totalTransferOut;
    return { ...w, balance: calculatedBalance, initial_balance: initialBalance };
  });

  return { ...state, wallets };
}

class LocalDatabase {
  private memoryCache: LocalDatabaseState | null = null;

  public getDeviceId(): string {
    const key = 'simo_device_id';
    let id = localStorage.getItem(key);
    if (!id) {
      id = generateUUID();
      localStorage.setItem(key, id);
    }
    return id;
  }

  public getLastSyncedTime(): string | null {
    return localStorage.getItem('simo_last_synced_time');
  }

  public setLastSyncedTime(time: string): void {
    localStorage.setItem('simo_last_synced_time', time);
  }

  public loadState(): LocalDatabaseState {
    if (this.memoryCache) return this.memoryCache;

    const state = getInitialDBState();
    const tables: (keyof LocalDatabaseState)[] = [
      'wallets',
      'wallet_transfers',
      'categories',
      'transactions',
      'monthly_budgets',
      'category_monthly_budgets',
      'saving_goals',
      'saving_goal_logs',
      'loan_contacts',
      'loan_transactions',
      'recurring_configs',
      'deletions',
    ];

    for (const table of tables) {
      try {
        const raw = localStorage.getItem(`${DB_PREFIX}${table}`);
        if (raw) {
          state[table] = JSON.parse(raw);
        }
      } catch (err) {
        console.warn(`Failed to parse table ${table} from local storage:`, err);
      }
    }

    const balancedState = recalculateWalletBalances(state);
    this.memoryCache = balancedState;
    return balancedState;
  }

  public saveTable<K extends keyof LocalDatabaseState>(table: K, data: LocalDatabaseState[K]): void {
    if (!this.memoryCache) this.loadState();
    if (this.memoryCache) {
      this.memoryCache[table] = data;
    }
    try {
      localStorage.setItem(`${DB_PREFIX}${table}`, JSON.stringify(data));
    } catch (err) {
      console.error(`Failed to save table ${table} to local storage:`, err);
    }
  }

  public saveAll(state: LocalDatabaseState): void {
    const balanced = recalculateWalletBalances(state);
    this.memoryCache = balanced;
    const tables = Object.keys(balanced) as (keyof LocalDatabaseState)[];
    for (const table of tables) {
      this.saveTable(table, balanced[table]);
    }
  }

  public addTombstone(id: string, tableName: string): void {
    if (!id) return;
    const state = this.loadState();
    const tombstone: PendingDeletion = {
      id: generateUUID(),
      cloud_id: id,
      table_name: tableName,
      deleted_at: new Date().toISOString(),
    };
    const updated = [...state.deletions, tombstone];
    this.saveTable('deletions', updated);
  }

  public getUnsyncedServerMutations(): ServerSyncMutations {
    const state = this.loadState();
    return {
      wallets: state.wallets
        .filter((i) => i.synced === 0)
        .map((w) => ({
          id: w.id || w.cloud_id,
          name: w.name,
          type: w.type,
          initial_balance: Number(w.initial_balance ?? w.balance ?? 0),
          color: w.color || '#10B981',
          icon: w.icon || 'wallet',
          currency: w.currency || 'VND',
          is_default: Boolean(w.is_default),
          exclude_from_total: Boolean(w.exclude_from_total),
          priority: Number(w.priority || 0),
          created_at: w.created_at || new Date().toISOString(),
          updated_at: w.updated_at || new Date().toISOString(),
        })),
      wallet_transfers: state.wallet_transfers
        .filter((i) => i.synced === 0)
        .map((wt) => ({
          id: wt.id || wt.cloud_id,
          source_wallet_id: wt.source_wallet_id || wt.from_wallet_id,
          destination_wallet_id: wt.destination_wallet_id || wt.to_wallet_id,
          amount: Number(wt.amount || 0),
          fee: Number(wt.fee || 0),
          transfer_date: wt.transfer_date || wt.date || new Date().toISOString(),
          note: wt.note || undefined,
          created_at: wt.created_at || new Date().toISOString(),
          updated_at: wt.updated_at || new Date().toISOString(),
        })),
      categories: state.categories
        .filter((i) => i.synced === 0)
        .map((c) => ({
          id: c.id || c.cloud_id,
          name: c.name,
          type: c.type,
          icon: c.icon || 'tag',
          color: c.color || '#3B82F6',
          budget_limit: c.budget_limit !== undefined ? Number(c.budget_limit) : undefined,
          created_at: c.created_at || new Date().toISOString(),
          updated_at: c.updated_at || new Date().toISOString(),
        })),
      transactions: state.transactions
        .filter((i) => i.synced === 0)
        .map((t) => ({
          id: t.id || t.cloud_id,
          wallet_id: t.wallet_id || undefined,
          category_id: t.category_id || undefined,
          recurring_config_id: t.recurring_config_id || undefined,
          amount: Number(t.amount || 0),
          formula: t.formula || undefined,
          note: t.note || undefined,
          type: t.type,
          transaction_date: t.transaction_date || t.date || new Date().toISOString().substring(0, 10),
          created_at: t.created_at || new Date().toISOString(),
          updated_at: t.updated_at || new Date().toISOString(),
        })),
      monthly_budgets: state.monthly_budgets
        .filter((i) => i.synced === 0)
        .map((mb) => ({
          id: mb.id || mb.cloud_id,
          year: Number(mb.year),
          month: Number(mb.month),
          amount: Number(mb.amount),
          created_at: mb.created_at || new Date().toISOString(),
          updated_at: mb.updated_at || new Date().toISOString(),
        })),
      category_monthly_budgets: state.category_monthly_budgets
        .filter((i) => i.synced === 0)
        .map((cmb) => ({
          id: cmb.id || cmb.cloud_id,
          category_id: cmb.category_id,
          year: Number(cmb.year),
          month: Number(cmb.month),
          amount: Number(cmb.amount),
          created_at: cmb.created_at || new Date().toISOString(),
          updated_at: cmb.updated_at || new Date().toISOString(),
        })),
      saving_goals: state.saving_goals
        .filter((i) => i.synced === 0)
        .map((sg) => ({
          id: sg.id || sg.cloud_id,
          name: sg.name,
          target_amount: Number(sg.target_amount),
          current_amount: Number(sg.current_amount || 0),
          target_date: sg.target_date || undefined,
          color: sg.color || undefined,
          icon: sg.icon || undefined,
          note: sg.note || undefined,
          status: sg.status || 'active',
          created_at: sg.created_at || new Date().toISOString(),
          updated_at: sg.updated_at || new Date().toISOString(),
        })),
      saving_goal_logs: state.saving_goal_logs
        .filter((i) => i.synced === 0)
        .map((sgl) => ({
          id: sgl.id || sgl.cloud_id,
          goal_id: sgl.goal_id,
          amount: Number(sgl.amount),
          type: sgl.type,
          log_date: sgl.log_date || sgl.date || new Date().toISOString(),
          note: sgl.note || undefined,
          created_at: sgl.created_at || new Date().toISOString(),
          updated_at: sgl.updated_at || new Date().toISOString(),
        })),
      loan_contacts: state.loan_contacts
        .filter((i) => i.synced === 0)
        .map((lc) => ({
          id: lc.id || lc.cloud_id,
          contact_name: lc.contact_name || lc.name,
          type: (lc.type || 'lend') as string,
          total_amount: Number(lc.total_amount || 0),
          remaining_amount: Number(lc.remaining_amount || 0),
          status: lc.status || 'active',
          created_at: lc.created_at || new Date().toISOString(),
          updated_at: lc.updated_at || new Date().toISOString(),
        })),
      loan_transactions: state.loan_transactions
        .filter((i) => i.synced === 0)
        .map((lt) => ({
          id: lt.id || lt.cloud_id,
          loan_id: lt.loan_id || lt.contact_id,
          amount: Number(lt.amount),
          type: lt.type,
          date: lt.date || new Date().toISOString(),
          due_date: lt.due_date || undefined,
          note: lt.note || undefined,
          created_at: lt.created_at || new Date().toISOString(),
          updated_at: lt.updated_at || new Date().toISOString(),
        })),
      recurring_configs: state.recurring_configs
        .filter((i) => i.synced === 0)
        .map((rc) => ({
          id: rc.id || rc.cloud_id,
          category_id: rc.category_id || undefined,
          wallet_id: rc.wallet_id || undefined,
          name: rc.name || 'Giao dịch định kỳ',
          amount: Number(rc.amount),
          type: (rc.type || 'expense') as string,
          frequency: rc.frequency,
          interval: Number(rc.interval || 1),
          day_of_week: rc.day_of_week !== undefined ? Number(rc.day_of_week) : undefined,
          day_of_month: rc.day_of_month !== undefined ? Number(rc.day_of_month) : undefined,
          next_run: rc.next_run || rc.next_run_date || new Date().toISOString(),
          is_active: Boolean(rc.is_active),
          created_at: rc.created_at || new Date().toISOString(),
          updated_at: rc.updated_at || new Date().toISOString(),
        })),
      deletions: state.deletions.map((d) => ({
        table_name: d.table_name,
        id: d.cloud_id || d.id,
        deleted_at: d.deleted_at || new Date().toISOString(),
      })),
    };
  }

  public markSynced(serverTime: string): void {
    const state = this.loadState();

    const markTable = <T extends { id: string; cloud_id?: string; synced: number }>(items: T[]): T[] => {
      return items.map((item) => ({ ...item, synced: 1 }));
    };

    state.wallets = markTable(state.wallets);
    state.wallet_transfers = markTable(state.wallet_transfers);
    state.categories = markTable(state.categories);
    state.transactions = markTable(state.transactions);
    state.monthly_budgets = markTable(state.monthly_budgets);
    state.category_monthly_budgets = markTable(state.category_monthly_budgets);
    state.saving_goals = markTable(state.saving_goals);
    state.saving_goal_logs = markTable(state.saving_goal_logs);
    state.loan_contacts = markTable(state.loan_contacts);
    state.loan_transactions = markTable(state.loan_transactions);
    state.recurring_configs = markTable(state.recurring_configs);

    // Clear processed deletions
    state.deletions = [];

    this.saveAll(state);
    this.setLastSyncedTime(serverTime);
  }

  public clearAll(): void {
    const tables: (keyof LocalDatabaseState)[] = [
      'wallets',
      'wallet_transfers',
      'categories',
      'transactions',
      'monthly_budgets',
      'category_monthly_budgets',
      'saving_goals',
      'saving_goal_logs',
      'loan_contacts',
      'loan_transactions',
      'recurring_configs',
      'deletions',
    ];
    for (const table of tables) {
      localStorage.removeItem(`${DB_PREFIX}${table}`);
    }
    localStorage.removeItem('simo_last_synced_time');
    this.memoryCache = getInitialDBState();
  }
}

export const localDb = new LocalDatabase();

