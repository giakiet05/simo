import React from 'react';
import { Search, Filter, RotateCcw } from 'lucide-react';
import { useFinance } from '../contexts/FinanceContext';
import type { TransactionFilterCriteria, TransactionType } from '../types';

interface TransactionFilterBarProps {
  criteria: TransactionFilterCriteria;
  onChange: (newCriteria: TransactionFilterCriteria) => void;
}

export const TransactionFilterBar: React.FC<TransactionFilterBarProps> = ({
  criteria,
  onChange,
}) => {
  const { wallets, categories } = useFinance();

  const handleTypeChange = (type: TransactionType | 'all') => {
    onChange({ ...criteria, type });
  };

  const handleWalletChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    onChange({ ...criteria, walletId: e.target.value || undefined });
  };

  const handleCategoryChange = (e: React.ChangeEvent<HTMLSelectElement>) => {
    const val = e.target.value;
    onChange({ ...criteria, categoryIds: val ? [val] : undefined });
  };

  const handleKeywordChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    onChange({ ...criteria, keyword: e.target.value });
  };

  const handleReset = () => {
    onChange({});
  };

  const setThisMonth = () => {
    const now = new Date();
    const firstDay = new Date(now.getFullYear(), now.getMonth(), 1).toISOString().split('T')[0];
    const lastDay = new Date(now.getFullYear(), now.getMonth() + 1, 0).toISOString().split('T')[0];
    onChange({ ...criteria, startDate: firstDay, endDate: lastDay });
  };

  const setLastMonth = () => {
    const now = new Date();
    const firstDay = new Date(now.getFullYear(), now.getMonth() - 1, 1).toISOString().split('T')[0];
    const lastDay = new Date(now.getFullYear(), now.getMonth(), 0).toISOString().split('T')[0];
    onChange({ ...criteria, startDate: firstDay, endDate: lastDay });
  };

  const hasActiveFilters = Boolean(
    criteria.type ||
      criteria.walletId ||
      criteria.categoryIds?.length ||
      criteria.startDate ||
      criteria.endDate ||
      criteria.keyword
  );

  return (
    <div className="bg-white dark:bg-slate-900 border border-slate-200/80 dark:border-slate-800 rounded-2xl p-4 shadow-xs space-y-3">
      <div className="flex flex-wrap items-center gap-3">
        {/* Search input */}
        <div className="flex-1 min-w-[200px] relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Tìm theo ghi chú, danh mục..."
            value={criteria.keyword || ''}
            onChange={handleKeywordChange}
            className="w-full pl-9 pr-3.5 py-2 bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700 rounded-xl text-xs sm:text-sm text-slate-900 dark:text-slate-100 placeholder:text-slate-400 focus:outline-none focus:border-teal-500"
          />
        </div>

        {/* Type selector */}
        <div className="flex items-center p-1 bg-slate-100 dark:bg-slate-800 rounded-xl text-xs font-semibold">
          <button
            onClick={() => handleTypeChange('all')}
            className={`px-3 py-1.5 rounded-lg transition-colors cursor-pointer ${
              !criteria.type || criteria.type === 'all'
                ? 'bg-white dark:bg-slate-700 text-slate-900 dark:text-slate-100 shadow-xs'
                : 'text-slate-600 dark:text-slate-400'
            }`}
          >
            Tất cả
          </button>
          <button
            onClick={() => handleTypeChange('expense')}
            className={`px-3 py-1.5 rounded-lg transition-colors cursor-pointer ${
              criteria.type === 'expense'
                ? 'bg-rose-500 text-white shadow-xs'
                : 'text-slate-600 dark:text-slate-400'
            }`}
          >
            Chi tiêu
          </button>
          <button
            onClick={() => handleTypeChange('income')}
            className={`px-3 py-1.5 rounded-lg transition-colors cursor-pointer ${
              criteria.type === 'income'
                ? 'bg-emerald-500 text-white shadow-xs'
                : 'text-slate-600 dark:text-slate-400'
            }`}
          >
            Thu nhập
          </button>
        </div>

        {/* Wallets Filter */}
        <select
          value={criteria.walletId || ''}
          onChange={handleWalletChange}
          className="px-3 py-2 bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700 rounded-xl text-xs sm:text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:border-teal-500"
        >
          <option value="">Tất cả các ví</option>
          {wallets.map((w) => (
            <option key={w.cloud_id} value={w.cloud_id}>
              {w.name}
            </option>
          ))}
        </select>

        {/* Categories Filter */}
        <select
          value={criteria.categoryIds?.[0] || ''}
          onChange={handleCategoryChange}
          className="px-3 py-2 bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-slate-700 rounded-xl text-xs sm:text-sm text-slate-900 dark:text-slate-100 focus:outline-none focus:border-teal-500"
        >
          <option value="">Tất cả danh mục</option>
          {categories.map((c) => (
            <option key={c.cloud_id} value={c.cloud_id}>
              {c.name} ({c.type === 'expense' ? 'Chi' : 'Thu'})
            </option>
          ))}
        </select>

        {/* Reset button */}
        {hasActiveFilters && (
          <button
            onClick={handleReset}
            className="flex items-center gap-1.5 px-3 py-2 text-xs font-medium text-slate-500 hover:text-rose-500 rounded-xl hover:bg-rose-50 dark:hover:bg-rose-950/30 transition-colors cursor-pointer"
            title="Xóa bộ lọc"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            <span>Đặt lại</span>
          </button>
        )}
      </div>

      {/* Quick date range presets */}
      <div className="flex items-center gap-2 pt-1 border-t border-slate-100 dark:border-slate-800/80 text-xs text-slate-500">
        <Filter className="w-3.5 h-3.5 text-slate-400" />
        <span>Khoảng thời gian:</span>
        <button
          onClick={setThisMonth}
          className="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 font-medium transition-colors cursor-pointer"
        >
          Tháng này
        </button>
        <button
          onClick={setLastMonth}
          className="px-2.5 py-1 rounded-lg bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700 text-slate-700 dark:text-slate-300 font-medium transition-colors cursor-pointer"
        >
          Tháng trước
        </button>
        <div className="flex items-center gap-1 ml-auto">
          <input
            type="date"
            value={criteria.startDate || ''}
            onChange={(e) => onChange({ ...criteria, startDate: e.target.value || undefined })}
            className="px-2 py-0.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-md text-[11px]"
          />
          <span>-</span>
          <input
            type="date"
            value={criteria.endDate || ''}
            onChange={(e) => onChange({ ...criteria, endDate: e.target.value || undefined })}
            className="px-2 py-0.5 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-md text-[11px]"
          />
        </div>
      </div>
    </div>
  );
};
