import React, { createContext, useContext, useEffect, useState, useCallback, useMemo } from 'react';
import type {
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
  SyncStatus,
  TransactionFilterCriteria,
} from '../types';
import { localDb, generateUUID } from '../services/db';
import { syncService } from '../services/syncService';
import { getAuthToken } from '../services/api';

interface FinanceContextType {
  // State
  wallets: Wallet[];
  walletTransfers: WalletTransfer[];
  categories: Category[];
  transactions: Transaction[];
  monthlyBudgets: MonthlyBudget[];
  categoryMonthlyBudgets: CategoryMonthlyBudget[];
  savingGoals: SavingGoal[];
  savingGoalLogs: SavingGoalLog[];
  loanContacts: LoanContact[];
  loanTransactions: LoanTransaction[];
  recurringConfigs: RecurringConfig[];
  syncStatus: SyncStatus;

  // Sync
  syncNow: () => Promise<boolean>;

  // Wallet operations
  addWallet: (data: Omit<Wallet, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => Promise<Wallet>;
  updateWallet: (cloudId: string, updates: Partial<Wallet>) => Promise<void>;
  deleteWallet: (cloudId: string) => Promise<void>;
  transferFunds: (data: Omit<WalletTransfer, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => Promise<void>;

  // Transaction operations
  addTransaction: (data: Omit<Transaction, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => Promise<Transaction>;
  updateTransaction: (cloudId: string, updates: Partial<Transaction>) => Promise<void>;
  deleteTransaction: (cloudId: string) => Promise<void>;
  bulkDeleteTransactions: (cloudIds: string[]) => Promise<void>;
  bulkUpdateCategory: (cloudIds: string[], categoryId: string) => Promise<void>;
  bulkUpdateDate: (cloudIds: string[], newDate: string) => Promise<void>;
  bulkUpdateWallet: (cloudIds: string[], walletId: string) => Promise<void>;

  // Category operations
  addCategory: (data: Omit<Category, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => Promise<Category>;
  updateCategory: (cloudId: string, updates: Partial<Category>) => Promise<void>;
  deleteCategory: (cloudId: string) => Promise<void>;

  // Budget operations
  setMonthlyBudget: (month: number, year: number, amount: number) => Promise<void>;
  setCategoryMonthlyBudget: (categoryId: string, month: number, year: number, amount: number) => Promise<void>;
  deleteCategoryMonthlyBudget: (cloudId: string) => Promise<void>;

  // Saving Goal operations
  addSavingGoal: (data: Omit<SavingGoal, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => Promise<SavingGoal>;
  updateSavingGoal: (cloudId: string, updates: Partial<SavingGoal>) => Promise<void>;
  deleteSavingGoal: (cloudId: string) => Promise<void>;
  depositSavingGoal: (goalId: string, walletId: string, amount: number, note?: string) => Promise<void>;
  withdrawSavingGoal: (goalId: string, walletId: string, amount: number, note?: string) => Promise<void>;

  // Loan & Debt operations
  addLoanContact: (data: Omit<LoanContact, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => Promise<LoanContact>;
  updateLoanContact: (cloudId: string, updates: Partial<LoanContact>) => Promise<void>;
  deleteLoanContact: (cloudId: string) => Promise<void>;
  addLoanTransaction: (data: Omit<LoanTransaction, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => Promise<LoanTransaction>;
  deleteLoanTransaction: (cloudId: string) => Promise<void>;

  // Recurring operations
  addRecurringConfig: (data: Omit<RecurringConfig, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => Promise<RecurringConfig>;
  updateRecurringConfig: (cloudId: string, updates: Partial<RecurringConfig>) => Promise<void>;
  deleteRecurringConfig: (cloudId: string) => Promise<void>;

  // Computed overview metrics
  totalNetWorth: number;
  currentMonthIncome: number;
  currentMonthExpense: number;
  currentMonthBalance: number;
  currentMonthBudgetAmount: number;
  categoryShares: Array<{ category_id: string; category_name: string; color: string; total_amount: number; percentage: number }>;

  // Filter helper
  filterTransactions: (criteria: TransactionFilterCriteria) => Transaction[];
}

const FinanceContext = createContext<FinanceContextType | undefined>(undefined);

export const FinanceProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [dbState, setDbState] = useState(() => localDb.loadState());
  const [syncStatus, setSyncStatus] = useState<SyncStatus>(() => syncService.getStatus());

  const refreshFromDb = useCallback(() => {
    setDbState({ ...localDb.loadState() });
  }, []);

  useEffect(() => {
    const unsub = syncService.subscribe((status) => {
      setSyncStatus(status);
      refreshFromDb();
    });
    return unsub;
  }, [refreshFromDb]);

  // Initial sync and default state initialization
  useEffect(() => {
    const token = getAuthToken();
    if (token) {
      syncService.syncNow().catch((err) => console.warn('Finance mount sync:', err));
    }
  }, [refreshFromDb]);

  // Sync operations
  const syncNow = useCallback(async () => {
    const res = await syncService.syncNow();
    refreshFromDb();
    return res;
  }, [refreshFromDb]);

  // Wallet operations
  const addWallet = async (data: Omit<Wallet, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => {
    const id = generateUUID();
    const now = new Date().toISOString();
    const newWallet: Wallet = { ...data, id, cloud_id: id, synced: 0, updated_at: now };
    const state = localDb.loadState();
    state.wallets = [...state.wallets, newWallet];
    localDb.saveTable('wallets', state.wallets);
    refreshFromDb();
    syncService.triggerDebouncedSync();
    return newWallet;
  };

  const updateWallet = async (cloudId: string, updates: Partial<Wallet>) => {
    const state = localDb.loadState();
    const now = new Date().toISOString();
    state.wallets = state.wallets.map((w) =>
      w.cloud_id === cloudId ? { ...w, ...updates, synced: 0, updated_at: now } : w
    );
    localDb.saveTable('wallets', state.wallets);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const deleteWallet = async (cloudId: string) => {
    const state = localDb.loadState();
    state.wallets = state.wallets.filter((w) => w.cloud_id !== cloudId);
    localDb.saveTable('wallets', state.wallets);
    localDb.addTombstone(cloudId, 'wallets');
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const transferFunds = async (data: Omit<WalletTransfer, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => {
    const id = generateUUID();
    const now = new Date().toISOString();
    const transfer: WalletTransfer = { ...data, id, cloud_id: id, synced: 0, updated_at: now };
    const state = localDb.loadState();

    // Adjust balances
    state.wallets = state.wallets.map((w) => {
      if (w.cloud_id === data.from_wallet_id) {
        return { ...w, balance: w.balance - (data.amount + (data.fee || 0)), synced: 0, updated_at: now };
      }
      if (w.cloud_id === data.to_wallet_id) {
        return { ...w, balance: w.balance + data.amount, synced: 0, updated_at: now };
      }
      return w;
    });

    state.wallet_transfers = [...state.wallet_transfers, transfer];
    localDb.saveTable('wallets', state.wallets);
    localDb.saveTable('wallet_transfers', state.wallet_transfers);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  // Transaction operations
  const addTransaction = async (data: Omit<Transaction, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => {
    const id = generateUUID();
    const now = new Date().toISOString();
    const newTx: Transaction = { ...data, id, cloud_id: id, synced: 0, updated_at: now };
    const state = localDb.loadState();

    // Adjust wallet balance if associated
    if (data.wallet_id) {
      state.wallets = state.wallets.map((w) => {
        if (w.cloud_id === data.wallet_id) {
          const delta = data.type === 'income' ? data.amount : -data.amount;
          return { ...w, balance: w.balance + delta, synced: 0, updated_at: now };
        }
        return w;
      });
      localDb.saveTable('wallets', state.wallets);
    }

    state.transactions = [newTx, ...state.transactions];
    localDb.saveTable('transactions', state.transactions);
    refreshFromDb();
    syncService.triggerDebouncedSync();
    return newTx;
  };

  const updateTransaction = async (cloudId: string, updates: Partial<Transaction>) => {
    const state = localDb.loadState();
    const now = new Date().toISOString();
    const oldTx = state.transactions.find((t) => t.cloud_id === cloudId);

    if (oldTx && updates.amount !== undefined) {
      // Revert old effect and apply new
      state.wallets = state.wallets.map((w) => {
        let b = w.balance;
        if (oldTx.wallet_id && w.cloud_id === oldTx.wallet_id) {
          b -= oldTx.type === 'income' ? oldTx.amount : -oldTx.amount;
        }
        const targetWalletId = updates.wallet_id || oldTx.wallet_id;
        const targetType = updates.type || oldTx.type;
        const targetAmount = updates.amount !== undefined ? updates.amount : oldTx.amount;
        if (targetWalletId && w.cloud_id === targetWalletId) {
          b += targetType === 'income' ? targetAmount : -targetAmount;
        }
        return { ...w, balance: b, synced: 0, updated_at: now };
      });
      localDb.saveTable('wallets', state.wallets);
    }

    state.transactions = state.transactions.map((t) =>
      t.cloud_id === cloudId ? { ...t, ...updates, synced: 0, updated_at: now } : t
    );
    localDb.saveTable('transactions', state.transactions);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const deleteTransaction = async (cloudId: string) => {
    const state = localDb.loadState();
    const now = new Date().toISOString();
    const tx = state.transactions.find((t) => t.cloud_id === cloudId);

    if (tx && tx.wallet_id) {
      state.wallets = state.wallets.map((w) => {
        if (w.cloud_id === tx.wallet_id) {
          const delta = tx.type === 'income' ? -tx.amount : tx.amount;
          return { ...w, balance: w.balance + delta, synced: 0, updated_at: now };
        }
        return w;
      });
      localDb.saveTable('wallets', state.wallets);
    }

    state.transactions = state.transactions.filter((t) => t.cloud_id !== cloudId);
    localDb.saveTable('transactions', state.transactions);
    localDb.addTombstone(cloudId, 'transactions');
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const bulkDeleteTransactions = async (cloudIds: string[]) => {
    const set = new Set(cloudIds);
    const state = localDb.loadState();
    const now = new Date().toISOString();

    state.transactions.forEach((tx) => {
      if (set.has(tx.cloud_id)) {
        if (tx.wallet_id) {
          state.wallets = state.wallets.map((w) => {
            if (w.cloud_id === tx.wallet_id) {
              const delta = tx.type === 'income' ? -tx.amount : tx.amount;
              return { ...w, balance: w.balance + delta, synced: 0, updated_at: now };
            }
            return w;
          });
        }
        localDb.addTombstone(tx.cloud_id, 'transactions');
      }
    });

    state.transactions = state.transactions.filter((t) => !set.has(t.cloud_id));
    localDb.saveTable('wallets', state.wallets);
    localDb.saveTable('transactions', state.transactions);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const bulkUpdateCategory = async (cloudIds: string[], categoryId: string) => {
    const set = new Set(cloudIds);
    const state = localDb.loadState();
    const now = new Date().toISOString();
    state.transactions = state.transactions.map((t) =>
      set.has(t.cloud_id) ? { ...t, category_id: categoryId, synced: 0, updated_at: now } : t
    );
    localDb.saveTable('transactions', state.transactions);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const bulkUpdateDate = async (cloudIds: string[], newDate: string) => {
    const set = new Set(cloudIds);
    const state = localDb.loadState();
    const now = new Date().toISOString();
    state.transactions = state.transactions.map((t) =>
      set.has(t.cloud_id) ? { ...t, date: newDate, synced: 0, updated_at: now } : t
    );
    localDb.saveTable('transactions', state.transactions);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const bulkUpdateWallet = async (cloudIds: string[], walletId: string) => {
    const set = new Set(cloudIds);
    const state = localDb.loadState();
    const now = new Date().toISOString();
    state.transactions = state.transactions.map((t) =>
      set.has(t.cloud_id) ? { ...t, wallet_id: walletId, synced: 0, updated_at: now } : t
    );
    localDb.saveTable('transactions', state.transactions);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  // Category operations
  const addCategory = async (data: Omit<Category, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => {
    const id = generateUUID();
    const now = new Date().toISOString();
    const cat: Category = { ...data, id, cloud_id: id, synced: 0, updated_at: now };
    const state = localDb.loadState();
    state.categories = [...state.categories, cat];
    localDb.saveTable('categories', state.categories);
    refreshFromDb();
    syncService.triggerDebouncedSync();
    return cat;
  };

  const updateCategory = async (cloudId: string, updates: Partial<Category>) => {
    const state = localDb.loadState();
    const now = new Date().toISOString();
    state.categories = state.categories.map((c) =>
      c.cloud_id === cloudId ? { ...c, ...updates, synced: 0, updated_at: now } : c
    );
    localDb.saveTable('categories', state.categories);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const deleteCategory = async (cloudId: string) => {
    const state = localDb.loadState();
    state.categories = state.categories.filter((c) => c.cloud_id !== cloudId);
    localDb.saveTable('categories', state.categories);
    localDb.addTombstone(cloudId, 'categories');
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  // Budget operations
  const setMonthlyBudget = async (month: number, year: number, amount: number) => {
    const state = localDb.loadState();
    const now = new Date().toISOString();
    const existing = state.monthly_budgets.find((b) => b.month === month && b.year === year);
    if (existing) {
      state.monthly_budgets = state.monthly_budgets.map((b) =>
        b.cloud_id === existing.cloud_id ? { ...b, amount, synced: 0, updated_at: now } : b
      );
    } else {
      const id = generateUUID();
      state.monthly_budgets.push({ id, cloud_id: id, month, year, amount, synced: 0, updated_at: now });
    }
    localDb.saveTable('monthly_budgets', state.monthly_budgets);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const setCategoryMonthlyBudget = async (categoryId: string, month: number, year: number, amount: number) => {
    const state = localDb.loadState();
    const now = new Date().toISOString();
    const existing = state.category_monthly_budgets.find(
      (b) => b.category_id === categoryId && b.month === month && b.year === year
    );
    if (existing) {
      state.category_monthly_budgets = state.category_monthly_budgets.map((b) =>
        b.cloud_id === existing.cloud_id ? { ...b, amount, synced: 0, updated_at: now } : b
      );
    } else {
      const id = generateUUID();
      state.category_monthly_budgets.push({
        id,
        cloud_id: id,
        category_id: categoryId,
        month,
        year,
        amount,
        synced: 0,
        updated_at: now,
      });
    }
    localDb.saveTable('category_monthly_budgets', state.category_monthly_budgets);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const deleteCategoryMonthlyBudget = async (cloudId: string) => {
    const state = localDb.loadState();
    state.category_monthly_budgets = state.category_monthly_budgets.filter((b) => b.cloud_id !== cloudId);
    localDb.saveTable('category_monthly_budgets', state.category_monthly_budgets);
    localDb.addTombstone(cloudId, 'category_monthly_budgets');
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  // Saving Goals operations
  const addSavingGoal = async (data: Omit<SavingGoal, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => {
    const id = generateUUID();
    const now = new Date().toISOString();
    const goal: SavingGoal = { ...data, id, cloud_id: id, synced: 0, updated_at: now };
    const state = localDb.loadState();
    state.saving_goals = [...state.saving_goals, goal];
    localDb.saveTable('saving_goals', state.saving_goals);
    refreshFromDb();
    syncService.triggerDebouncedSync();
    return goal;
  };

  const updateSavingGoal = async (cloudId: string, updates: Partial<SavingGoal>) => {
    const state = localDb.loadState();
    const now = new Date().toISOString();
    state.saving_goals = state.saving_goals.map((g) =>
      g.cloud_id === cloudId ? { ...g, ...updates, synced: 0, updated_at: now } : g
    );
    localDb.saveTable('saving_goals', state.saving_goals);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const deleteSavingGoal = async (cloudId: string) => {
    const state = localDb.loadState();
    state.saving_goals = state.saving_goals.filter((g) => g.cloud_id !== cloudId);
    localDb.saveTable('saving_goals', state.saving_goals);
    localDb.addTombstone(cloudId, 'saving_goals');
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const depositSavingGoal = async (goalId: string, walletId: string, amount: number, note?: string) => {
    const id = generateUUID();
    const now = new Date().toISOString();
    const state = localDb.loadState();

    // 1. Create log
    const log: SavingGoalLog = {
      id,
      cloud_id: id,
      goal_id: goalId,
      wallet_id: walletId,
      amount,
      type: 'deposit',
      date: now,
      note,
      synced: 0,
      updated_at: now,
    };
    state.saving_goal_logs.push(log);

    // 2. Adjust goal current amount
    state.saving_goals = state.saving_goals.map((g) =>
      g.cloud_id === goalId ? { ...g, current_amount: g.current_amount + amount, synced: 0, updated_at: now } : g
    );

    // 3. Deduct from wallet
    state.wallets = state.wallets.map((w) =>
      w.cloud_id === walletId ? { ...w, balance: w.balance - amount, synced: 0, updated_at: now } : w
    );

    localDb.saveTable('saving_goal_logs', state.saving_goal_logs);
    localDb.saveTable('saving_goals', state.saving_goals);
    localDb.saveTable('wallets', state.wallets);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const withdrawSavingGoal = async (goalId: string, walletId: string, amount: number, note?: string) => {
    const id = generateUUID();
    const now = new Date().toISOString();
    const state = localDb.loadState();

    const log: SavingGoalLog = {
      id,
      cloud_id: id,
      goal_id: goalId,
      wallet_id: walletId,
      amount,
      type: 'withdraw',
      date: now,
      note,
      synced: 0,
      updated_at: now,
    };
    state.saving_goal_logs.push(log);

    state.saving_goals = state.saving_goals.map((g) =>
      g.cloud_id === goalId ? { ...g, current_amount: Math.max(0, g.current_amount - amount), synced: 0, updated_at: now } : g
    );

    state.wallets = state.wallets.map((w) =>
      w.cloud_id === walletId ? { ...w, balance: w.balance + amount, synced: 0, updated_at: now } : w
    );

    localDb.saveTable('saving_goal_logs', state.saving_goal_logs);
    localDb.saveTable('saving_goals', state.saving_goals);
    localDb.saveTable('wallets', state.wallets);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  // Loan & Debt operations
  const addLoanContact = async (data: Omit<LoanContact, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => {
    const id = generateUUID();
    const now = new Date().toISOString();
    const contact: LoanContact = { ...data, id, cloud_id: id, synced: 0, updated_at: now };
    const state = localDb.loadState();
    state.loan_contacts.push(contact);
    localDb.saveTable('loan_contacts', state.loan_contacts);
    refreshFromDb();
    syncService.triggerDebouncedSync();
    return contact;
  };

  const updateLoanContact = async (cloudId: string, updates: Partial<LoanContact>) => {
    const state = localDb.loadState();
    const now = new Date().toISOString();
    state.loan_contacts = state.loan_contacts.map((c) =>
      c.cloud_id === cloudId ? { ...c, ...updates, synced: 0, updated_at: now } : c
    );
    localDb.saveTable('loan_contacts', state.loan_contacts);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const deleteLoanContact = async (cloudId: string) => {
    const state = localDb.loadState();
    state.loan_contacts = state.loan_contacts.filter((c) => c.cloud_id !== cloudId);
    localDb.saveTable('loan_contacts', state.loan_contacts);
    localDb.addTombstone(cloudId, 'loan_contacts');
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const addLoanTransaction = async (data: Omit<LoanTransaction, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => {
    const id = generateUUID();
    const now = new Date().toISOString();
    const loanTx: LoanTransaction = { ...data, id, cloud_id: id, synced: 0, updated_at: now };
    const state = localDb.loadState();

    if (data.wallet_id) {
      state.wallets = state.wallets.map((w) => {
        if (w.cloud_id === data.wallet_id) {
          let delta = 0;
          if (data.type === 'lend' || data.type === 'repayment_paid') delta = -data.amount;
          else if (data.type === 'borrow' || data.type === 'repayment_received') delta = data.amount;
          return { ...w, balance: w.balance + delta, synced: 0, updated_at: now };
        }
        return w;
      });
      localDb.saveTable('wallets', state.wallets);
    }

    state.loan_transactions.push(loanTx);
    localDb.saveTable('loan_transactions', state.loan_transactions);
    refreshFromDb();
    syncService.triggerDebouncedSync();
    return loanTx;
  };

  const deleteLoanTransaction = async (cloudId: string) => {
    const state = localDb.loadState();
    state.loan_transactions = state.loan_transactions.filter((t) => t.cloud_id !== cloudId);
    localDb.saveTable('loan_transactions', state.loan_transactions);
    localDb.addTombstone(cloudId, 'loan_transactions');
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  // Recurring operations
  const addRecurringConfig = async (data: Omit<RecurringConfig, 'id' | 'cloud_id' | 'synced' | 'updated_at'>) => {
    const id = generateUUID();
    const now = new Date().toISOString();
    const config: RecurringConfig = { ...data, id, cloud_id: id, synced: 0, updated_at: now };
    const state = localDb.loadState();
    state.recurring_configs.push(config);
    localDb.saveTable('recurring_configs', state.recurring_configs);
    refreshFromDb();
    syncService.triggerDebouncedSync();
    return config;
  };

  const updateRecurringConfig = async (cloudId: string, updates: Partial<RecurringConfig>) => {
    const state = localDb.loadState();
    const now = new Date().toISOString();
    state.recurring_configs = state.recurring_configs.map((c) =>
      c.cloud_id === cloudId ? { ...c, ...updates, synced: 0, updated_at: now } : c
    );
    localDb.saveTable('recurring_configs', state.recurring_configs);
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  const deleteRecurringConfig = async (cloudId: string) => {
    const state = localDb.loadState();
    state.recurring_configs = state.recurring_configs.filter((c) => c.cloud_id !== cloudId);
    localDb.saveTable('recurring_configs', state.recurring_configs);
    localDb.addTombstone(cloudId, 'recurring_configs');
    refreshFromDb();
    syncService.triggerDebouncedSync();
  };

  // Computed metrics
  const totalNetWorth = useMemo(() => {
    return dbState.wallets
      .filter((w) => !w.exclude_from_total)
      .reduce((sum, w) => sum + (Number(w.balance) || 0), 0);
  }, [dbState.wallets]);

  const currentMonthDate = new Date();
  const currentMonth = currentMonthDate.getMonth() + 1;
  const currentYear = currentMonthDate.getFullYear();

  const currentMonthTransactions = useMemo(() => {
    return dbState.transactions.filter((tx) => {
      if (!tx.date) return false;
      const d = new Date(tx.date);
      return d.getMonth() + 1 === currentMonth && d.getFullYear() === currentYear;
    });
  }, [dbState.transactions, currentMonth, currentYear]);

  const currentMonthIncome = useMemo(() => {
    return currentMonthTransactions
      .filter((t) => t.type === 'income')
      .reduce((sum, t) => sum + (Number(t.amount) || 0), 0);
  }, [currentMonthTransactions]);

  const currentMonthExpense = useMemo(() => {
    return currentMonthTransactions
      .filter((t) => t.type === 'expense')
      .reduce((sum, t) => sum + (Number(t.amount) || 0), 0);
  }, [currentMonthTransactions]);

  const currentMonthBalance = currentMonthIncome - currentMonthExpense;

  const currentMonthBudgetAmount = useMemo(() => {
    const b = dbState.monthly_budgets.find((mb) => mb.month === currentMonth && mb.year === currentYear);
    return b ? Number(b.amount) : 0;
  }, [dbState.monthly_budgets, currentMonth, currentYear]);

  const categoryShares = useMemo(() => {
    const map = new Map<string, number>();
    currentMonthTransactions
      .filter((t) => t.type === 'expense' && t.category_id)
      .forEach((t) => {
        const catId = t.category_id!;
        map.set(catId, (map.get(catId) || 0) + Number(t.amount));
      });

    const totalExp = currentMonthExpense || 1;
    const catMap = new Map(dbState.categories.map((c) => [c.cloud_id, c]));

    return Array.from(map.entries()).map(([catId, total]) => {
      const cat = catMap.get(catId);
      return {
        category_id: catId,
        category_name: cat ? cat.name : 'Khác',
        color: cat?.color || '#94A3B8',
        total_amount: total,
        percentage: Math.round((total / totalExp) * 100),
      };
    });
  }, [currentMonthTransactions, currentMonthExpense, dbState.categories]);

  // Filter transactions helper
  const filterTransactions = useCallback(
    (criteria: TransactionFilterCriteria): Transaction[] => {
      return dbState.transactions.filter((tx) => {
        if (criteria.type && criteria.type !== 'all' && tx.type !== criteria.type) {
          return false;
        }
        if (criteria.walletId && tx.wallet_id !== criteria.walletId) {
          return false;
        }
        if (criteria.categoryIds && criteria.categoryIds.length > 0) {
          if (!tx.category_id || !criteria.categoryIds.includes(tx.category_id)) {
            return false;
          }
        }
        if (criteria.startDate && tx.date) {
          if (new Date(tx.date) < new Date(criteria.startDate)) return false;
        }
        if (criteria.endDate && tx.date) {
          if (new Date(tx.date) > new Date(criteria.endDate + 'T23:59:59')) return false;
        }
        if (criteria.minAmount !== undefined && Number(tx.amount) < criteria.minAmount) {
          return false;
        }
        if (criteria.maxAmount !== undefined && Number(tx.amount) > criteria.maxAmount) {
          return false;
        }
        if (criteria.keyword && criteria.keyword.trim()) {
          const kw = criteria.keyword.toLowerCase().trim();
          const noteMatch = tx.note?.toLowerCase().includes(kw);
          const cat = dbState.categories.find((c) => c.cloud_id === tx.category_id);
          const catMatch = cat?.name.toLowerCase().includes(kw);
          if (!noteMatch && !catMatch) return false;
        }
        return true;
      });
    },
    [dbState.transactions, dbState.categories]
  );

  return (
    <FinanceContext.Provider
      value={{
        wallets: dbState.wallets,
        walletTransfers: dbState.wallet_transfers,
        categories: dbState.categories,
        transactions: dbState.transactions,
        monthlyBudgets: dbState.monthly_budgets,
        categoryMonthlyBudgets: dbState.category_monthly_budgets,
        savingGoals: dbState.saving_goals,
        savingGoalLogs: dbState.saving_goal_logs,
        loanContacts: dbState.loan_contacts,
        loanTransactions: dbState.loan_transactions,
        recurringConfigs: dbState.recurring_configs,
        syncStatus,
        syncNow,
        addWallet,
        updateWallet,
        deleteWallet,
        transferFunds,
        addTransaction,
        updateTransaction,
        deleteTransaction,
        bulkDeleteTransactions,
        bulkUpdateCategory,
        bulkUpdateDate,
        bulkUpdateWallet,
        addCategory,
        updateCategory,
        deleteCategory,
        setMonthlyBudget,
        setCategoryMonthlyBudget,
        deleteCategoryMonthlyBudget,
        addSavingGoal,
        updateSavingGoal,
        deleteSavingGoal,
        depositSavingGoal,
        withdrawSavingGoal,
        addLoanContact,
        updateLoanContact,
        deleteLoanContact,
        addLoanTransaction,
        deleteLoanTransaction,
        addRecurringConfig,
        updateRecurringConfig,
        deleteRecurringConfig,
        totalNetWorth,
        currentMonthIncome,
        currentMonthExpense,
        currentMonthBalance,
        currentMonthBudgetAmount,
        categoryShares,
        filterTransactions,
      }}
    >
      {children}
    </FinanceContext.Provider>
  );
};

export const useFinance = (): FinanceContextType => {
  const context = useContext(FinanceContext);
  if (!context) {
    throw new Error('useFinance must be used within a FinanceProvider');
  }
  return context;
};
