import React, { useState, useEffect } from 'react';
import { Modal, Input, Button } from './ui';
import { useFinance } from '../contexts/FinanceContext';

interface BudgetModalProps {
  isOpen: boolean;
  onClose: () => void;
  month: number;
  year: number;
}

export const BudgetModal: React.FC<BudgetModalProps> = ({
  isOpen,
  onClose,
  month,
  year,
}) => {
  const {
    categories,
    monthlyBudgets,
    categoryMonthlyBudgets,
    setMonthlyBudget,
    setCategoryMonthlyBudget,
  } = useFinance();

  const [totalAmount, setTotalAmount] = useState('');
  const [categoryAmounts, setCategoryAmounts] = useState<Record<string, string>>({});
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const expenseCategories = categories.filter((c) => c.type === 'expense');

  useEffect(() => {
    const mb = monthlyBudgets.find((b) => b.month === month && b.year === year);
    setTotalAmount(mb ? mb.amount.toString() : '');

    const catMap: Record<string, string> = {};
    categoryMonthlyBudgets
      .filter((cb) => cb.month === month && cb.year === year)
      .forEach((cb) => {
        catMap[cb.category_id] = cb.amount.toString();
      });
    setCategoryAmounts(catMap);
    setError(null);
  }, [isOpen, month, year, monthlyBudgets, categoryMonthlyBudgets]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    setIsSubmitting(true);
    setError(null);

    try {
      const numTotal = totalAmount ? parseFloat(totalAmount.replace(/,/g, '')) : 0;
      await setMonthlyBudget(month, year, numTotal);

      for (const cat of expenseCategories) {
        const val = categoryAmounts[cat.cloud_id];
        const numVal = val ? parseFloat(val.replace(/,/g, '')) : 0;
        await setCategoryMonthlyBudget(cat.cloud_id, month, year, numVal);
      }

      onClose();
    } catch (err: any) {
      setError(err.message || 'Lỗi khi lưu ngân sách');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`Thiết lập ngân sách Tháng ${month}/${year}`}
      description="Đặt hạn mức tổng chi tiêu và chi tiêu theo từng danh mục"
      maxWidth="lg"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="p-4 bg-teal-50 dark:bg-teal-950/30 border border-teal-200 dark:border-teal-800 rounded-2xl">
          <Input
            label="Tổng ngân sách chi tiêu cả tháng *"
            type="number"
            step="any"
            placeholder="0"
            value={totalAmount}
            onChange={(e) => setTotalAmount(e.target.value)}
            required
            autoFocus
          />
        </div>

        <div className="space-y-3 pt-2">
          <h4 className="text-xs font-bold uppercase tracking-wider text-slate-500">
            Hạn mức theo từng danh mục
          </h4>
          <div className="space-y-2 max-h-60 overflow-y-auto pr-1">
            {expenseCategories.map((cat) => (
              <div
                key={cat.cloud_id}
                className="flex items-center justify-between gap-4 p-2 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200/60 dark:border-slate-700/60"
              >
                <div className="flex items-center gap-2">
                  <div
                    className="w-3.5 h-3.5 rounded-full"
                    style={{ backgroundColor: cat.color || '#F97316' }}
                  />
                  <span className="text-xs font-semibold text-slate-800 dark:text-slate-200">
                    {cat.name}
                  </span>
                </div>
                <input
                  type="number"
                  step="any"
                  placeholder="0"
                  value={categoryAmounts[cat.cloud_id] || ''}
                  onChange={(e) =>
                    setCategoryAmounts({ ...categoryAmounts, [cat.cloud_id]: e.target.value })
                  }
                  className="w-36 px-2.5 py-1 text-right text-xs bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-700 rounded-lg focus:outline-none focus:border-teal-500"
                />
              </div>
            ))}
          </div>
        </div>

        {error && <p className="text-xs text-rose-500">{error}</p>}

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="outline" className="flex-1" onClick={onClose}>
            Hủy
          </Button>
          <Button type="submit" variant="primary" className="flex-1" isLoading={isSubmitting}>
            Lưu ngân sách
          </Button>
        </div>
      </form>
    </Modal>
  );
};
