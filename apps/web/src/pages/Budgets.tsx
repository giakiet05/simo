import { useState } from 'react';
import {
  ChevronLeft,
  ChevronRight,
  Plus,
  PieChart,
  Calendar,
} from 'lucide-react';
import { useFinance } from '../contexts/FinanceContext';
import { Card, Button, Badge } from '../components/ui';

interface BudgetsPageProps {
  onOpenBudgetModal: (month: number, year: number) => void;
}

export const BudgetsPage: React.FC<BudgetsPageProps> = ({ onOpenBudgetModal }) => {
  const {
    categories,
    transactions,
    monthlyBudgets,
    categoryMonthlyBudgets,
  } = useFinance();

  const [currentDate, setCurrentDate] = useState(() => new Date());

  const month = currentDate.getMonth() + 1;
  const year = currentDate.getFullYear();

  const handlePrevMonth = () => {
    setCurrentDate(new Date(year, month - 2, 1));
  };

  const handleNextMonth = () => {
    setCurrentDate(new Date(year, month, 1));
  };

  const handleCurrentMonth = () => {
    setCurrentDate(new Date());
  };

  // Month transactions
  const monthTransactions = transactions.filter((tx) => {
    if (!tx.date) return false;
    const d = new Date(tx.date);
    return d.getMonth() + 1 === month && d.getFullYear() === year;
  });

  const totalExpense = monthTransactions
    .filter((t) => t.type === 'expense')
    .reduce((sum, t) => sum + Number(t.amount), 0);

  const overallBudget = monthlyBudgets.find((b) => b.month === month && b.year === year);
  const budgetAmount = overallBudget ? Number(overallBudget.amount) : 0;
  const overallUsagePct = budgetAmount > 0 ? Math.round((totalExpense / budgetAmount) * 100) : 0;

  // Category budgets
  const expenseCategories = categories.filter((c) => c.type === 'expense');
  const catBudgets = categoryMonthlyBudgets.filter((cb) => cb.month === month && cb.year === year);
  const catBudgetMap = new Map(catBudgets.map((cb) => [cb.category_id, Number(cb.amount)]));

  // Category expenses
  const catExpenseMap = new Map<string, number>();
  monthTransactions
    .filter((t) => t.type === 'expense' && t.category_id)
    .forEach((t) => {
      const catId = t.category_id!;
      catExpenseMap.set(catId, (catExpenseMap.get(catId) || 0) + Number(t.amount));
    });

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Month Navigation & Action */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="flex items-center bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl p-1 shadow-xs">
            <button
              onClick={handlePrevMonth}
              className="p-1.5 rounded-xl hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-400 cursor-pointer"
              title="Tháng trước"
            >
              <ChevronLeft className="w-5 h-5" />
            </button>
            <span className="px-4 text-sm font-bold text-slate-900 dark:text-slate-100 min-w-[130px] text-center">
              Tháng {month} / {year}
            </span>
            <button
              onClick={handleNextMonth}
              className="p-1.5 rounded-xl hover:bg-slate-100 dark:hover:bg-slate-800 text-slate-600 dark:text-slate-400 cursor-pointer"
              title="Tháng sau"
            >
              <ChevronRight className="w-5 h-5" />
            </button>
          </div>
          <Button size="sm" variant="ghost" onClick={handleCurrentMonth}>
            <Calendar className="w-3.5 h-3.5" />
            <span>Tháng này</span>
          </Button>
        </div>

        <Button size="sm" variant="primary" onClick={() => onOpenBudgetModal(month, year)}>
          <Plus className="w-3.5 h-3.5" />
          <span>Thiết lập ngân sách</span>
        </Button>
      </div>

      {/* Overall Budget Overview Card */}
      <Card className="p-6">
        <div className="flex items-center justify-between pb-4 border-b border-slate-100 dark:border-slate-800">
          <div className="flex items-center gap-2">
            <PieChart className="w-5 h-5 text-teal-600 dark:text-teal-400" />
            <h2 className="text-base font-bold text-slate-900 dark:text-slate-100">
              Tổng quan ngân sách Tháng {month}/{year}
            </h2>
          </div>
          {budgetAmount > 0 && (
            <Badge
              variant={
                overallUsagePct > 100
                  ? 'danger'
                  : overallUsagePct >= 80
                  ? 'warning'
                  : 'success'
              }
            >
              Đã dùng {overallUsagePct}%
            </Badge>
          )}
        </div>

        {budgetAmount > 0 ? (
          <div className="mt-4 space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              <div>
                <span className="text-xs text-slate-400 font-medium">Hạn mức ngân sách</span>
                <p className="text-xl font-bold text-slate-900 dark:text-slate-100 mt-0.5">
                  {new Intl.NumberFormat('vi-VN').format(budgetAmount)} ₫
                </p>
              </div>
              <div>
                <span className="text-xs text-slate-400 font-medium">Đã chi tiêu</span>
                <p className="text-xl font-bold text-rose-600 dark:text-rose-400 mt-0.5">
                  {new Intl.NumberFormat('vi-VN').format(totalExpense)} ₫
                </p>
              </div>
              <div>
                <span className="text-xs text-slate-400 font-medium">Còn lại khả dụng</span>
                <p
                  className={`text-xl font-bold mt-0.5 ${
                    budgetAmount - totalExpense >= 0
                      ? 'text-emerald-600 dark:text-emerald-400'
                      : 'text-rose-600 dark:text-rose-400'
                  }`}
                >
                  {new Intl.NumberFormat('vi-VN').format(budgetAmount - totalExpense)} ₫
                </p>
              </div>
            </div>

            <div className="h-3.5 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
              <div
                className={`h-full rounded-full transition-all duration-500 ${
                  overallUsagePct > 100
                    ? 'bg-rose-500'
                    : overallUsagePct >= 80
                    ? 'bg-amber-500'
                    : 'bg-teal-500'
                }`}
                style={{ width: `${Math.min(100, overallUsagePct)}%` }}
              />
            </div>
          </div>
        ) : (
          <div className="text-center py-8 text-slate-400 space-y-3">
            <p className="text-sm">Chưa có ngân sách nào được thiết lập cho Tháng {month}/{year}</p>
            <Button size="sm" variant="primary" onClick={() => onOpenBudgetModal(month, year)}>
              Đặt ngân sách cho tháng này
            </Button>
          </div>
        )}
      </Card>

      {/* Category Budgets Grid */}
      <div className="space-y-3">
        <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
          Hạn mức theo từng danh mục chi tiêu
        </h3>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          {expenseCategories.map((cat) => {
            const limit = catBudgetMap.get(cat.cloud_id) || 0;
            const spent = catExpenseMap.get(cat.cloud_id) || 0;
            const pct = limit > 0 ? Math.round((spent / limit) * 100) : 0;

            return (
              <Card key={cat.cloud_id} className="p-4 space-y-3">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div
                      className="w-4 h-4 rounded-full shrink-0"
                      style={{ backgroundColor: cat.color || '#F97316' }}
                    />
                    <span className="text-xs font-bold text-slate-900 dark:text-slate-100">
                      {cat.name}
                    </span>
                  </div>

                  {limit > 0 ? (
                    <Badge
                      variant={
                        pct > 100 ? 'danger' : pct >= 80 ? 'warning' : 'success'
                      }
                    >
                      {pct}%
                    </Badge>
                  ) : (
                    <span className="text-[11px] text-slate-400">Chưa đặt hạn mức</span>
                  )}
                </div>

                {limit > 0 ? (
                  <>
                    <div className="flex justify-between text-xs text-slate-500">
                      <span>Đã chi: {new Intl.NumberFormat('vi-VN').format(spent)} ₫</span>
                      <span>Hạn mức: {new Intl.NumberFormat('vi-VN').format(limit)} ₫</span>
                    </div>

                    <div className="h-2 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                      <div
                        className={`h-full rounded-full transition-all duration-300 ${
                          pct > 100
                            ? 'bg-rose-500'
                            : pct >= 80
                            ? 'bg-amber-500'
                            : 'bg-teal-500'
                        }`}
                        style={{ width: `${Math.min(100, pct)}%` }}
                      />
                    </div>
                  </>
                ) : (
                  <div className="flex justify-between text-xs text-slate-400">
                    <span>Đã chi: {new Intl.NumberFormat('vi-VN').format(spent)} ₫</span>
                  </div>
                )}
              </Card>
            );
          })}
        </div>
      </div>
    </div>
  );
};
