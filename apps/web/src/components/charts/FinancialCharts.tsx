import React from 'react';

interface CategoryShare {
  category_id: string;
  category_name: string;
  color: string;
  total_amount: number;
  percentage: number;
}

interface CategoryDonutChartProps {
  shares: CategoryShare[];
  totalExpense: number;
}

export const CategoryDonutChart: React.FC<CategoryDonutChartProps> = ({
  shares,
  totalExpense,
}) => {
  if (shares.length === 0 || totalExpense === 0) {
    return (
      <div className="h-64 flex flex-col items-center justify-center text-slate-400 text-xs gap-2">
        <div className="w-20 h-20 rounded-full border-4 border-dashed border-slate-200 dark:border-slate-800" />
        <span>Chưa có dữ liệu chi tiêu trong khoảng thời gian này</span>
      </div>
    );
  }

  // Calculate SVG donut segments
  const size = 200;
  const strokeWidth = 28;
  const radius = (size - strokeWidth) / 2;
  const circumference = 2 * Math.PI * radius;

  const segments = shares.reduce<Array<CategoryShare & { strokeDasharray: string; strokeDashoffset: number }>>(
    (acc, share) => {
      const prevOffset = acc.length > 0 ? -acc[acc.length - 1].strokeDashoffset + (parseFloat(acc[acc.length - 1].strokeDasharray.split(' ')[0]) || 0) : 0;
      const strokeDasharray = `${(share.percentage / 100) * circumference} ${circumference}`;
      acc.push({
        ...share,
        strokeDasharray,
        strokeDashoffset: -prevOffset,
      });
      return acc;
    },
    []
  );

  return (
    <div className="flex flex-col md:flex-row items-center justify-center gap-6 py-4">
      {/* SVG Donut */}
      <div className="relative w-48 h-48 flex items-center justify-center shrink-0">
        <svg className="w-full h-full -rotate-90" viewBox={`0 0 ${size} ${size}`}>
          <circle
            cx={size / 2}
            cy={size / 2}
            r={radius}
            fill="transparent"
            stroke="currentColor"
            strokeWidth={strokeWidth}
            className="text-slate-100 dark:text-slate-800"
          />
          {segments.map((seg) => (
            <circle
              key={seg.category_id}
              cx={size / 2}
              cy={size / 2}
              r={radius}
              fill="transparent"
              stroke={seg.color || '#94A3B8'}
              strokeWidth={strokeWidth}
              strokeDasharray={seg.strokeDasharray}
              strokeDashoffset={seg.strokeDashoffset}
              strokeLinecap="butt"
              className="transition-all duration-300 hover:opacity-80"
            />
          ))}
        </svg>
        <div className="absolute flex flex-col items-center justify-center text-center p-2">
          <span className="text-[10px] text-slate-400 font-medium uppercase tracking-wider">
            Tổng chi tiêu
          </span>
          <span className="text-sm font-bold text-slate-900 dark:text-slate-100">
            {new Intl.NumberFormat('vi-VN').format(totalExpense)} ₫
          </span>
        </div>
      </div>

      {/* Legend */}
      <div className="flex-1 w-full space-y-2 max-h-56 overflow-y-auto pr-2">
        {shares.map((share) => (
          <div
            key={share.category_id}
            className="flex items-center justify-between gap-3 text-xs p-1.5 rounded-lg hover:bg-slate-50 dark:hover:bg-slate-800/40"
          >
            <div className="flex items-center gap-2 min-w-0">
              <div
                className="w-3 h-3 rounded-full shrink-0"
                style={{ backgroundColor: share.color || '#94A3B8' }}
              />
              <span className="font-medium text-slate-700 dark:text-slate-200 truncate">
                {share.category_name}
              </span>
            </div>
            <div className="flex items-center gap-3 shrink-0 text-right">
              <span className="text-slate-500 font-mono text-[11px]">{share.percentage}%</span>
              <span className="font-semibold text-slate-900 dark:text-slate-100">
                {new Intl.NumberFormat('vi-VN').format(share.total_amount)} ₫
              </span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};

interface CashflowTrendsProps {
  income: number;
  expense: number;
  balance: number;
}

export const CashflowTrendsBar: React.FC<CashflowTrendsProps> = ({
  income,
  expense,
  balance,
}) => {
  const maxVal = Math.max(income, expense, 1);
  const incomePct = Math.round((income / maxVal) * 100);
  const expensePct = Math.round((expense / maxVal) * 100);

  return (
    <div className="space-y-4 py-2">
      {/* Income Bar */}
      <div className="space-y-1.5">
        <div className="flex justify-between text-xs">
          <span className="font-semibold text-emerald-600 dark:text-emerald-400">Tổng thu nhập</span>
          <span className="font-bold text-slate-900 dark:text-slate-100">
            +{new Intl.NumberFormat('vi-VN').format(income)} ₫
          </span>
        </div>
        <div className="h-3 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
          <div
            className="h-full bg-emerald-500 rounded-full transition-all duration-500"
            style={{ width: `${incomePct}%` }}
          />
        </div>
      </div>

      {/* Expense Bar */}
      <div className="space-y-1.5">
        <div className="flex justify-between text-xs">
          <span className="font-semibold text-rose-600 dark:text-rose-400">Tổng chi tiêu</span>
          <span className="font-bold text-slate-900 dark:text-slate-100">
            -{new Intl.NumberFormat('vi-VN').format(expense)} ₫
          </span>
        </div>
        <div className="h-3 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
          <div
            className="h-full bg-rose-500 rounded-full transition-all duration-500"
            style={{ width: `${expensePct}%` }}
          />
        </div>
      </div>

      {/* Net Balance Callout */}
      <div className="pt-2 border-t border-slate-100 dark:border-slate-800 flex justify-between items-center text-xs">
        <span className="text-slate-500">Dòng tiền ròng (Net Savings):</span>
        <span
          className={`font-bold text-sm ${
            balance >= 0
              ? 'text-emerald-600 dark:text-emerald-400'
              : 'text-rose-600 dark:text-rose-400'
          }`}
        >
          {balance >= 0 ? '+' : ''}
          {new Intl.NumberFormat('vi-VN').format(balance)} ₫
        </span>
      </div>
    </div>
  );
};
