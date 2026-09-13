import { useState } from 'react';
import { GoogleOAuthProvider } from '@react-oauth/google';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import { ThemeProvider } from './contexts/ThemeContext';
import { FinanceProvider } from './contexts/FinanceContext';
import { Login } from './pages/Login';
import { Navbar } from './components/Navbar';
import { Sidebar, type TabId } from './components/Sidebar';

// Pages
import { DashboardPage } from './pages/Dashboard';
import { TransactionsPage } from './pages/Transactions';
import { WalletsPage } from './pages/Wallets';
import { WalletDetailPage } from './pages/WalletDetail';
import { BudgetsPage } from './pages/Budgets';
import { SavingGoalsPage } from './pages/SavingGoals';
import { LoansPage } from './pages/Loans';
import { RecurringPage } from './pages/Recurring';
import { ReportsPage } from './pages/Reports';
import { ExportBackupPage } from './pages/ExportBackup';
import { SettingsPage } from './pages/Settings';

// Modals
import { TransactionModal } from './components/TransactionModal';
import { WalletModal } from './components/WalletModal';
import { WalletTransferModal } from './components/WalletTransferModal';
import { CategoryModal } from './components/CategoryModal';
import { BudgetModal } from './components/BudgetModal';
import { SavingGoalModal } from './components/SavingGoalModal';
import { SavingGoalLogModal } from './components/SavingGoalLogModal';
import { LoanContactModal, LoanTransactionModal } from './components/LoanModal';
import { RecurringModal } from './components/RecurringModal';

import type {
  Transaction,
  Wallet,
  Category,
  SavingGoal,
  LoanContact,
  LoanType,
  RecurringConfig,
} from './types';

const GOOGLE_CLIENT_ID =
  import.meta.env.VITE_GOOGLE_CLIENT_ID ||
  '249729017539-b22m2t1b958l3d24olhp249h3r26bn6a.apps.googleusercontent.com';

function AuthenticatedApp() {
  const { isAuthenticated, isLoading: authLoading } = useAuth();
  const [activeTab, setActiveTab] = useState<TabId>('dashboard');
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  // Selected entities for drill-down views & editing
  const [selectedWalletDetail, setSelectedWalletDetail] = useState<Wallet | null>(null);

  // Modal States
  const [transactionModalOpen, setTransactionModalOpen] = useState(false);
  const [editingTransaction, setEditingTransaction] = useState<Transaction | null>(null);

  const [walletModalOpen, setWalletModalOpen] = useState(false);
  const [editingWallet, setEditingWallet] = useState<Wallet | null>(null);

  const [transferModalOpen, setTransferModalOpen] = useState(false);

  const [categoryModalOpen, setCategoryModalOpen] = useState(false);
  const [editingCategory, setEditingCategory] = useState<Category | null>(null);

  const [budgetModalOpen, setBudgetModalOpen] = useState(false);
  const [budgetModalDate, setBudgetModalDate] = useState<{ month: number; year: number }>({
    month: new Date().getMonth() + 1,
    year: new Date().getFullYear(),
  });

  const [savingGoalModalOpen, setSavingGoalModalOpen] = useState(false);
  const [editingSavingGoal, setEditingSavingGoal] = useState<SavingGoal | null>(null);

  const [savingGoalLogModalOpen, setSavingGoalLogModalOpen] = useState(false);
  const [savingGoalLogData, setSavingGoalLogData] = useState<{
    goal: SavingGoal | null;
    mode: 'deposit' | 'withdraw';
  }>({ goal: null, mode: 'deposit' });

  const [loanContactModalOpen, setLoanContactModalOpen] = useState(false);
  const [editingLoanContact, setEditingLoanContact] = useState<LoanContact | null>(null);

  const [loanTransactionModalOpen, setLoanTransactionModalOpen] = useState(false);
  const [loanTransactionData, setLoanTransactionData] = useState<{
    contact: LoanContact | null;
    defaultType: LoanType;
  }>({ contact: null, defaultType: 'lend' });

  const [recurringModalOpen, setRecurringModalOpen] = useState(false);
  const [editingRecurring, setEditingRecurring] = useState<RecurringConfig | null>(null);

  if (authLoading) {
    return (
      <div className="min-h-screen bg-white dark:bg-slate-950 text-slate-900 dark:text-slate-100 flex items-center justify-center">
        <div className="flex flex-col items-center gap-3">
          <div className="w-8 h-8 border-2 border-teal-600 border-t-transparent rounded-full animate-spin" />
          <span className="text-xs text-slate-500">Đang khởi động Simo Finance...</span>
        </div>
      </div>
    );
  }

  if (!isAuthenticated) {
    return <Login />;
  }

  const handleTabChange = (tab: TabId) => {
    setActiveTab(tab);
    setSelectedWalletDetail(null);
    setMobileMenuOpen(false);
  };

  return (
    <div className="min-h-screen bg-[var(--bg-app)] text-[var(--text-primary)] flex">
      {/* Desktop Sidebar */}
      <Sidebar
        activeTab={activeTab}
        onTabChange={handleTabChange}
        onOpenNewTransaction={() => {
          setEditingTransaction(null);
          setTransactionModalOpen(true);
        }}
        onOpenTransfer={() => setTransferModalOpen(true)}
        className="hidden md:flex"
      />

      {/* Mobile Drawer */}
      {mobileMenuOpen && (
        <div className="fixed inset-0 z-50 md:hidden flex">
          <div
            className="fixed inset-0 bg-slate-900/60 backdrop-blur-xs"
            onClick={() => setMobileMenuOpen(false)}
          />
          <Sidebar
            activeTab={activeTab}
            onTabChange={handleTabChange}
            onOpenNewTransaction={() => {
              setEditingTransaction(null);
              setTransactionModalOpen(true);
              setMobileMenuOpen(false);
            }}
            onOpenTransfer={() => {
              setTransferModalOpen(true);
              setMobileMenuOpen(false);
            }}
            className="relative z-10 w-72 shadow-2xl animate-in slide-in-from-left duration-200"
          />
        </div>
      )}

      {/* Main Content Area */}
      <div className="flex-1 flex flex-col min-w-0">
        <Navbar
          activeTab={activeTab}
          onToggleMobileMenu={() => setMobileMenuOpen(!mobileMenuOpen)}
        />

        <main className="flex-1 max-w-7xl w-full mx-auto p-4 sm:p-6 lg:p-8">
          {/* Active Tab Router */}
          {activeTab === 'dashboard' && (
            <DashboardPage
              onNavigate={handleTabChange}
              onOpenNewTransaction={() => {
                setEditingTransaction(null);
                setTransactionModalOpen(true);
              }}
              onOpenTransfer={() => setTransferModalOpen(true)}
              onOpenBudget={() => {
                setBudgetModalDate({
                  month: new Date().getMonth() + 1,
                  year: new Date().getFullYear(),
                });
                setBudgetModalOpen(true);
              }}
            />
          )}

          {activeTab === 'transactions' && (
            <TransactionsPage
              onOpenNewTransaction={() => {
                setEditingTransaction(null);
                setTransactionModalOpen(true);
              }}
              onEditTransaction={(tx) => {
                setEditingTransaction(tx);
                setTransactionModalOpen(true);
              }}
            />
          )}

          {activeTab === 'wallets' &&
            (selectedWalletDetail ? (
              <WalletDetailPage
                wallet={selectedWalletDetail}
                onBack={() => setSelectedWalletDetail(null)}
                onOpenNewTransaction={() => {
                  setEditingTransaction(null);
                  setTransactionModalOpen(true);
                }}
              />
            ) : (
              <WalletsPage
                onOpenNewWallet={() => {
                  setEditingWallet(null);
                  setWalletModalOpen(true);
                }}
                onOpenTransfer={() => setTransferModalOpen(true)}
                onEditWallet={(w) => {
                  setEditingWallet(w);
                  setWalletModalOpen(true);
                }}
                onViewWalletDetail={(w) => setSelectedWalletDetail(w)}
              />
            ))}

          {activeTab === 'budgets' && (
            <BudgetsPage
              onOpenBudgetModal={(m, y) => {
                setBudgetModalDate({ month: m, year: y });
                setBudgetModalOpen(true);
              }}
            />
          )}

          {activeTab === 'saving-goals' && (
            <SavingGoalsPage
              onOpenNewGoal={() => {
                setEditingSavingGoal(null);
                setSavingGoalModalOpen(true);
              }}
              onEditGoal={(goal) => {
                setEditingSavingGoal(goal);
                setSavingGoalModalOpen(true);
              }}
              onOpenDeposit={(goal) => {
                setSavingGoalLogData({ goal, mode: 'deposit' });
                setSavingGoalLogModalOpen(true);
              }}
              onOpenWithdraw={(goal) => {
                setSavingGoalLogData({ goal, mode: 'withdraw' });
                setSavingGoalLogModalOpen(true);
              }}
            />
          )}

          {activeTab === 'loans' && (
            <LoansPage
              onOpenNewContact={() => {
                setEditingLoanContact(null);
                setLoanContactModalOpen(true);
              }}
              onEditContact={(contact) => {
                setEditingLoanContact(contact);
                setLoanContactModalOpen(true);
              }}
              onOpenLoanTransaction={(contact, defaultType) => {
                setLoanTransactionData({ contact, defaultType: defaultType || 'lend' });
                setLoanTransactionModalOpen(true);
              }}
            />
          )}

          {activeTab === 'recurring' && (
            <RecurringPage
              onOpenNewRecurring={() => {
                setEditingRecurring(null);
                setRecurringModalOpen(true);
              }}
              onEditRecurring={(cfg) => {
                setEditingRecurring(cfg);
                setRecurringModalOpen(true);
              }}
            />
          )}

          {activeTab === 'reports' && <ReportsPage />}

          {activeTab === 'export-backup' && <ExportBackupPage />}

          {activeTab === 'settings' && (
            <SettingsPage
              onOpenCategoryModal={(cat) => {
                setEditingCategory(cat || null);
                setCategoryModalOpen(true);
              }}
            />
          )}
        </main>

        <footer className="border-t border-slate-200/80 dark:border-slate-800/80 py-4 text-center text-xs text-slate-400">
          Simo Personal Finance Ecosystem • 1:1 Parity Web & Mobile Sync
        </footer>
      </div>

      {/* Global Modals */}
      <TransactionModal
        isOpen={transactionModalOpen}
        onClose={() => setTransactionModalOpen(false)}
        editingTransaction={editingTransaction}
      />

      <WalletModal
        isOpen={walletModalOpen}
        onClose={() => setWalletModalOpen(false)}
        editingWallet={editingWallet}
      />

      <WalletTransferModal
        isOpen={transferModalOpen}
        onClose={() => setTransferModalOpen(false)}
      />

      <CategoryModal
        isOpen={categoryModalOpen}
        onClose={() => setCategoryModalOpen(false)}
        editingCategory={editingCategory}
      />

      <BudgetModal
        isOpen={budgetModalOpen}
        onClose={() => setBudgetModalOpen(false)}
        month={budgetModalDate.month}
        year={budgetModalDate.year}
      />

      <SavingGoalModal
        isOpen={savingGoalModalOpen}
        onClose={() => setSavingGoalModalOpen(false)}
        editingGoal={editingSavingGoal}
      />

      <SavingGoalLogModal
        isOpen={savingGoalLogModalOpen}
        onClose={() => setSavingGoalLogModalOpen(false)}
        goal={savingGoalLogData.goal}
        mode={savingGoalLogData.mode}
      />

      <LoanContactModal
        isOpen={loanContactModalOpen}
        onClose={() => setLoanContactModalOpen(false)}
        editingContact={editingLoanContact}
      />

      <LoanTransactionModal
        isOpen={loanTransactionModalOpen}
        onClose={() => setLoanTransactionModalOpen(false)}
        contact={loanTransactionData.contact}
        defaultType={loanTransactionData.defaultType}
      />

      <RecurringModal
        isOpen={recurringModalOpen}
        onClose={() => setRecurringModalOpen(false)}
        editingConfig={editingRecurring}
      />
    </div>
  );
}

export function App() {
  return (
    <GoogleOAuthProvider clientId={GOOGLE_CLIENT_ID}>
      <AuthProvider>
        <ThemeProvider>
          <FinanceProvider>
            <AuthenticatedApp />
          </FinanceProvider>
        </ThemeProvider>
      </AuthProvider>
    </GoogleOAuthProvider>
  );
}

export default App;
