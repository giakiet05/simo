import { useState, useMemo } from 'react';
import { BarChart3, FileSpreadsheet } from 'lucide-react';
import { useFinance } from '../contexts/FinanceContext';
import { Card, Button } from '../components/ui';
import { CategoryDonutChart, CashflowTrendsBar } from '../components/charts/FinancialCharts';
import { exportService } from '../services/exportService';

export const ReportsPage: React.FC = () => {
  const { transactions, categories, wallets } = useFinance();

  const [period, setPeriod] = useState<'this_month' | 'last_month' | 'this_year'>('this_month');

  const filteredTransactions = useMemo(() => {
    const now = new Date();
    return transactions.filter((tx) => {
      if (!tx.date) return false;
      const d = new Date(tx.date);
      if (period === 'this_month') {
        return d.getMonth() === now.getMonth() && d.getFullYear() === now.getFullYear();
      }
      if (period === 'last_month') {
        const lastM = now.getMonth() === 0 ? 11 : now.getMonth() - 1;
        const lastY = now.getMonth() === 0 ? now.getFullYear() - 1 : now.getFullYear();
        return d.getMonth() === lastM && d.getFullYear() === lastY;
      }
      if (period === 'this_year') {
        return d.getFullYear() === now.getFullYear();
      }
      return true;
    });
  }, [transactions, period]);

  const totalIncome = useMemo(() => {
    return filteredTransactions
      .filter((t) => t.type === 'income')
      .reduce((sum, t) => sum + Number(t.amount), 0);
  }, [filteredTransactions]);

  const totalExpense = useMemo(() => {
    return filteredTransactions
      .filter((t) => t.type === 'expense')
      .reduce((sum, t) => sum + Number(t.amount), 0);
  }, [filteredTransactions]);

  const netBalance = totalIncome - totalExpense;

  const categoryShares = useMemo(() => {
    const map = new Map<string, number>();
    filteredTransactions
      .filter((t) => t.type === 'expense' && t.category_id)
      .forEach((t) => {
        const catId = t.category_id!;
        map.set(catId, (map.get(catId) || 0) + Number(t.amount));
      });

    const totalExp = totalExpense || 1;
    const catMap = new Map(categories.map((c) => [c.cloud_id, c]));

    return Array.from(map.entries())
      .map(([catId, total]) => {
        const cat = catMap.get(catId);
        return {
          category_id: catId,
          category_name: cat ? cat.name : 'Khác',
          color: cat?.color || '#94A3B8',
          total_amount: total,
          percentage: Math.round((total / totalExp) * 100),
        };
      })
      .sort((a, b) => b.total_amount - a.total_amount);
  }, [filteredTransactions, totalExpense, categories]);

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Header & Filter Controls */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-slate-900 dark:text-slate-100 tracking-tight">
            Báo cáo & Phân tích chuyên sâu
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Biểu đồ trực quan hóa dòng tiền và cơ cấu chi tiêu theo danh mục
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="flex items-center p-1 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-xs text-xs font-semibold">
            <button
              onClick={() => setPeriod('this_month')}
              className={`px-3 py-1.5 rounded-xl transition-colors cursor-pointer ${
                period === 'this_month'
                  ? 'bg-teal-600 text-white shadow-xs'
                  : 'text-slate-600 dark:text-slate-400'
              }`}
            >
              Tháng này
            </button>
            <button
              onClick={() => setPeriod('last_month')}
              className={`px-3 py-1.5 rounded-xl transition-colors cursor-pointer ${
                period === 'last_month'
                  ? 'bg-teal-600 text-white shadow-xs'
                  : 'text-slate-600 dark:text-slate-400'
              }`}
            >
              Tháng trước
            </button>
            <button
              onClick={() => setPeriod('this_year')}
              className={`px-3 py-1.5 rounded-xl transition-colors cursor-pointer ${
                period === 'this_year'
                  ? 'bg-teal-600 text-white shadow-xs'
                  : 'text-slate-600 dark:text-slate-400'
              }`}
            >
              Năm nay
            </button>
          </div>

          <Button
            size="sm"
            variant="outline"
            onClick={() => exportService.exportToCSV(filteredTransactions, categories, wallets)}
          >
            <FileSpreadsheet className="w-3.5 h-3.5" />
            <span>Xuất CSV</span>
          </Button>
        </div>
      </div>

      {/* Overview Charts Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Cashflow Trend */}
        <Card className="p-6">
          <div className="flex items-center gap-2 pb-4 border-b border-slate-100 dark:border-slate-800">
            <BarChart3 className="w-5 h-5 text-teal-600 dark:text-teal-400" />
            <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
              Dòng tiền tổng quan
            </h3>
          </div>
          <CashflowTrendsBar income={totalIncome} expense={totalExpense} balance={netBalance} />
        </Card>

        {/* Category Breakdown Donut */}
        <Card className="p-6">
          <div className="flex items-center gap-2 pb-4 border-b border-slate-100 dark:border-slate-800">
            <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
              Cơ cấu chi tiêu
            </h3>
          </div>
          <CategoryDonutChart shares={categoryShares} totalExpense={totalExpense} />
        </Card>
      </div>

      {/* Top Spending Categories Table */}
      <Card className="p-0 overflow-hidden">
        <div className="p-4 border-b border-slate-100 dark:border-slate-800">
          <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
            Bảng chi tiết các khoản chi lớn nhất
          </h3>
        </div>

        <div className="divide-y divide-slate-100 dark:divide-slate-800">
          {categoryShares.length === 0 ? (
            <p className="text-xs text-slate-400 py-10 text-center">Chưa có chi tiêu trong kỳ</p>
          ) : (
            categoryShares.map((item, idx) => (
              <div key={item.category_id} className="flex items-center justify-between p-4">
                <div className="flex items-center gap-3">
                  <span className="w-5 text-xs font-bold text-slate-400">#{idx + 1}</span>
                  <div
                    className="w-3.5 h-3.5 rounded-full"
                    style={{ backgroundColor: item.color }}
                  />
                  <span className="text-xs font-bold text-slate-900 dark:text-slate-100">
                    {item.category_name}
                  </span>
                </div>

                <div className="flex items-center gap-4">
                  <span className="text-xs text-slate-500">{item.percentage}%</span>
                  <span className="text-xs font-bold text-rose-600 dark:text-rose-400">
                    -{new Intl.NumberFormat('vi-VN').format(item.total_amount)} ₫
                  </span>
                </div>
              </div>
            ))
          )}
        </div>
      </Card>
    </div>
  );
};
