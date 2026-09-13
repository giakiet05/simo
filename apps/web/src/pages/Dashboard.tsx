import React, { useState } from 'react';
import {
  TrendingUp,
  TrendingDown,
  Wallet,
  PiggyBank,
  Plus,
  ArrowLeftRight,
  PieChart,
  Eye,
  EyeOff,
  ChevronRight,
  AlertTriangle,
} from 'lucide-react';
import { useFinance } from '../contexts/FinanceContext';
import { Card, Badge, Button } from '../components/ui';
import { CategoryDonutChart } from '../components/charts/FinancialCharts';
import type { TabId } from '../components/Sidebar';

interface DashboardProps {
  onNavigate: (tab: TabId) => void;
  onOpenNewTransaction: () => void;
  onOpenTransfer: () => void;
  onOpenBudget: () => void;
}

export const DashboardPage: React.FC<DashboardProps> = ({
  onNavigate,
  onOpenNewTransaction,
  onOpenTransfer,
  onOpenBudget,
}) => {
  const {
    wallets,
    categories,
    transactions,
    totalNetWorth,
    currentMonthIncome,
    currentMonthExpense,
    currentMonthBalance,
    currentMonthBudgetAmount,
    categoryShares,
    savingGoals,
  } = useFinance();

  const [showBalance, setShowBalance] = useState(true);

  const budgetUsagePct = currentMonthBudgetAmount > 0
    ? Math.round((currentMonthExpense / currentMonthBudgetAmount) * 100)
    : 0;

  const recentTransactions = transactions.slice(0, 6);
  const catMap = new Map(categories.map((c) => [c.cloud_id, c]));
  const walletMap = new Map(wallets.map((w) => [w.cloud_id, w]));

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Quick Action Topbar */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-slate-900 dark:text-slate-100 tracking-tight">
            Tổng quan tài chính
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Theo dõi dòng tiền, số dư ví và tiến độ ngân sách tháng hiện tại
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button size="sm" variant="secondary" onClick={onOpenTransfer}>
            <ArrowLeftRight className="w-3.5 h-3.5" />
            <span>Chuyển tiền</span>
          </Button>
          <Button size="sm" variant="primary" onClick={onOpenNewTransaction}>
            <Plus className="w-3.5 h-3.5" />
            <span>Thêm giao dịch</span>
          </Button>
        </div>
      </div>

      {/* Hero Financial Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
        {/* Net Worth */}
        <Card className="bg-gradient-to-br from-slate-900 to-slate-800 text-white border-0 shadow-md">
          <div className="flex justify-between items-start">
            <span className="text-xs text-slate-300 font-medium">Tổng tài sản ròng</span>
            <button
              onClick={() => setShowBalance(!showBalance)}
              className="text-slate-400 hover:text-white cursor-pointer"
            >
              {showBalance ? <Eye className="w-4 h-4" /> : <EyeOff className="w-4 h-4" />}
            </button>
          </div>
          <div className="mt-3">
            <h2 className="text-2xl font-black tracking-tight">
              {showBalance
                ? `${new Intl.NumberFormat('vi-VN').format(totalNetWorth)} ₫`
                : '•••••••• ₫'}
            </h2>
            <div className="flex items-center gap-2 mt-2 text-[11px] text-slate-300">
              <Wallet className="w-3.5 h-3.5 text-teal-400" />
              <span>{wallets.length} tài khoản ví đang hoạt động</span>
            </div>
          </div>
        </Card>

        {/* Monthly Income */}
        <Card>
          <div className="flex justify-between items-start">
            <span className="text-xs text-slate-500 dark:text-slate-400 font-medium">
              Thu nhập tháng này
            </span>
            <div className="w-8 h-8 rounded-xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
              <TrendingUp className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-2">
            <h3 className="text-xl font-bold text-slate-900 dark:text-slate-100">
              +{new Intl.NumberFormat('vi-VN').format(currentMonthIncome)} ₫
            </h3>
            <span className="text-[11px] text-emerald-600 dark:text-emerald-400 font-medium mt-1 inline-block">
              Tổng các khoản thu
            </span>
          </div>
        </Card>

        {/* Monthly Expense */}
        <Card>
          <div className="flex justify-between items-start">
            <span className="text-xs text-slate-500 dark:text-slate-400 font-medium">
              Chi tiêu tháng này
            </span>
            <div className="w-8 h-8 rounded-xl bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 flex items-center justify-center">
              <TrendingDown className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-2">
            <h3 className="text-xl font-bold text-slate-900 dark:text-slate-100">
              -{new Intl.NumberFormat('vi-VN').format(currentMonthExpense)} ₫
            </h3>
            <span className="text-[11px] text-rose-600 dark:text-rose-400 font-medium mt-1 inline-block">
              Tổng các khoản chi
            </span>
          </div>
        </Card>

        {/* Net Savings */}
        <Card>
          <div className="flex justify-between items-start">
            <span className="text-xs text-slate-500 dark:text-slate-400 font-medium">
              Dư tích lũy tháng
            </span>
            <div className="w-8 h-8 rounded-xl bg-teal-50 dark:bg-teal-950/40 text-teal-600 dark:text-teal-400 flex items-center justify-center">
              <PiggyBank className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-2">
            <h3
              className={`text-xl font-bold ${
                currentMonthBalance >= 0
                  ? 'text-emerald-600 dark:text-emerald-400'
                  : 'text-rose-600 dark:text-rose-400'
              }`}
            >
              {currentMonthBalance >= 0 ? '+' : ''}
              {new Intl.NumberFormat('vi-VN').format(currentMonthBalance)} ₫
            </h3>
            <span className="text-[11px] text-slate-400 mt-1 inline-block">
              Thu nhập trừ chi tiêu
            </span>
          </div>
        </Card>
      </div>

      {/* Middle Grid: Budget Status & Category Breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Monthly Budget Card */}
        <Card className="lg:col-span-1 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
              <div className="flex items-center gap-2">
                <PieChart className="w-4 h-4 text-teal-600 dark:text-teal-400" />
                <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">Ngân sách tháng</h3>
              </div>
              <button
                onClick={onOpenBudget}
                className="text-xs text-teal-600 dark:text-teal-400 font-medium hover:underline cursor-pointer"
              >
                Cài đặt
              </button>
            </div>

            <div className="mt-4 space-y-4">
              {currentMonthBudgetAmount > 0 ? (
                <>
                  <div className="flex justify-between items-end">
                    <div>
                      <span className="text-[11px] text-slate-400">Đã chi / Hạn mức</span>
                      <p className="text-base font-bold text-slate-900 dark:text-slate-100">
                        {new Intl.NumberFormat('vi-VN').format(currentMonthExpense)} /{' '}
                        {new Intl.NumberFormat('vi-VN').format(currentMonthBudgetAmount)} ₫
                      </p>
                    </div>
                    <Badge
                      variant={
                        budgetUsagePct > 100
                          ? 'danger'
                          : budgetUsagePct >= 80
                          ? 'warning'
                          : 'success'
                      }
                    >
                      {budgetUsagePct}%
                    </Badge>
                  </div>

                  <div className="h-3 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                    <div
                      className={`h-full rounded-full transition-all duration-500 ${
                        budgetUsagePct > 100
                          ? 'bg-rose-500'
                          : budgetUsagePct >= 80
                          ? 'bg-amber-500'
                          : 'bg-teal-500'
                      }`}
                      style={{ width: `${Math.min(100, budgetUsagePct)}%` }}
                    />
                  </div>

                  {budgetUsagePct > 100 && (
                    <div className="flex items-center gap-2 p-2 rounded-xl bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 text-xs">
                      <AlertTriangle className="w-4 h-4 shrink-0" />
                      <span>Đã vượt ngân sách {budgetUsagePct - 100}%!</span>
                    </div>
                  )}
                </>
              ) : (
                <div className="text-center py-6 text-slate-400 space-y-2">
                  <p className="text-xs">Chưa thiết lập ngân sách chi tiêu tháng này</p>
                  <Button size="sm" variant="outline" onClick={onOpenBudget}>
                    Thiết lập ngay
                  </Button>
                </div>
              )}
            </div>
          </div>

          <div className="pt-4 border-t border-slate-100 dark:border-slate-800/80 mt-4">
            <button
              onClick={() => onNavigate('budgets')}
              className="w-full flex items-center justify-between text-xs font-semibold text-teal-600 dark:text-teal-400 hover:text-teal-700 cursor-pointer"
            >
              <span>Xem chi tiết từng danh mục</span>
              <ChevronRight className="w-4 h-4" />
            </button>
          </div>
        </Card>

        {/* Category Breakdown Donut */}
        <Card className="lg:col-span-2">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
            <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
              Phân bổ chi tiêu tháng này
            </h3>
            <button
              onClick={() => onNavigate('reports')}
              className="text-xs text-teal-600 dark:text-teal-400 font-medium hover:underline cursor-pointer"
            >
              Báo cáo đầy đủ
            </button>
          </div>
          <CategoryDonutChart shares={categoryShares} totalExpense={currentMonthExpense} />
        </Card>
      </div>

      {/* Bottom Grid: Saving Goals & Recent Transactions */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Saving Goals Widget */}
        <Card className="lg:col-span-1">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
            <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
              Mục tiêu tích lũy
            </h3>
            <button
              onClick={() => onNavigate('saving-goals')}
              className="text-xs text-teal-600 dark:text-teal-400 font-medium hover:underline cursor-pointer"
            >
              Tất cả ({savingGoals.length})
            </button>
          </div>

          <div className="mt-3 space-y-3">
            {savingGoals.length === 0 ? (
              <p className="text-xs text-slate-400 py-6 text-center">Chưa có mục tiêu tiết kiệm</p>
            ) : (
              savingGoals.slice(0, 3).map((goal) => {
                const pct = goal.target_amount > 0 ? Math.min(100, Math.round((goal.current_amount / goal.target_amount) * 100)) : 0;
                return (
                  <div
                    key={goal.cloud_id}
                    className="p-3 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200/60 dark:border-slate-700/60 space-y-2"
                  >
                    <div className="flex justify-between items-center text-xs">
                      <span className="font-semibold text-slate-900 dark:text-slate-100">{goal.name}</span>
                      <span className="font-bold text-teal-600 dark:text-teal-400">{pct}%</span>
                    </div>
                    <div className="h-2 bg-slate-200 dark:bg-slate-700 rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all"
                        style={{ width: `${pct}%`, backgroundColor: goal.color || '#10B981' }}
                      />
                    </div>
                    <div className="flex justify-between text-[11px] text-slate-400">
                      <span>{new Intl.NumberFormat('vi-VN').format(goal.current_amount)} ₫</span>
                      <span>{new Intl.NumberFormat('vi-VN').format(goal.target_amount)} ₫</span>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </Card>

        {/* Recent Transactions List */}
        <Card className="lg:col-span-2">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
            <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
              Giao dịch gần đây
            </h3>
            <button
              onClick={() => onNavigate('transactions')}
              className="text-xs text-teal-600 dark:text-teal-400 font-medium hover:underline cursor-pointer"
            >
              Xem tất cả ({transactions.length})
            </button>
          </div>

          <div className="mt-3 divide-y divide-slate-100 dark:divide-slate-800">
            {recentTransactions.length === 0 ? (
              <p className="text-xs text-slate-400 py-8 text-center">Chưa có giao dịch nào</p>
            ) : (
              recentTransactions.map((tx) => {
                const cat = catMap.get(tx.category_id || '');
                const wal = walletMap.get(tx.wallet_id || '');
                return (
                  <div
                    key={tx.cloud_id}
                    className="flex items-center justify-between py-2.5 px-1 hover:bg-slate-50 dark:hover:bg-slate-800/40 rounded-xl transition-colors"
                  >
                    <div className="flex items-center gap-3 min-w-0">
                      <div
                        className="w-8 h-8 rounded-xl flex items-center justify-center text-xs font-bold shrink-0 text-white"
                        style={{ backgroundColor: cat?.color || '#94A3B8' }}
                      >
                        {(cat?.name || 'K').charAt(0).toUpperCase()}
                      </div>
                      <div className="min-w-0">
                        <p className="text-xs font-semibold text-slate-900 dark:text-slate-100 truncate">
                          {tx.note || cat?.name || 'Giao dịch'}
                        </p>
                        <p className="text-[11px] text-slate-400">
                          {wal?.name || 'Ví'} • {tx.date ? new Date(tx.date).toLocaleDateString('vi-VN') : ''}
                        </p>
                      </div>
                    </div>
                    <span
                      className={`text-xs font-bold shrink-0 ${
                        tx.type === 'income'
                          ? 'text-emerald-600 dark:text-emerald-400'
                          : 'text-rose-600 dark:text-rose-400'
                      }`}
                    >
                      {tx.type === 'income' ? '+' : '-'}
                      {new Intl.NumberFormat('vi-VN').format(tx.amount)} ₫
                    </span>
                  </div>
                );
              })
            )}
          </div>
        </Card>
      </div>
    </div>
  );
};
