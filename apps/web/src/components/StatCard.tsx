import React from 'react';

interface StatCardProps {
  title: string;
  amount: number;
  icon: React.ReactNode;
  subtitle?: string;
  type?: 'default' | 'income' | 'expense' | 'budget';
}

export const StatCard: React.FC<StatCardProps> = ({ title, amount, icon, subtitle, type = 'default' }) => {
  const formatVND = (val: number) => {
    return new Intl.NumberFormat('vi-VN', { style: 'currency', currency: 'VND' }).format(val);
  };

  const getStyle = () => {
    switch (type) {
      case 'income':
        return 'border-emerald-500/20 bg-emerald-950/10 text-emerald-400';
      case 'expense':
        return 'border-rose-500/20 bg-rose-950/10 text-rose-400';
      case 'budget':
        return 'border-indigo-500/20 bg-indigo-950/10 text-indigo-400';
      default:
        return 'border-slate-800 bg-slate-900/50 text-slate-300';
    }
  };

  return (
    <div className={`p-5 rounded-2xl border backdrop-blur-sm transition-all hover:border-slate-700 ${getStyle()}`}>
      <div className="flex items-center justify-between mb-3">
        <span className="text-xs font-medium text-slate-400 uppercase tracking-wider">{title}</span>
        <div className="p-2 rounded-xl bg-slate-950/50 border border-slate-800">{icon}</div>
      </div>
      <div className="text-2xl font-bold text-white tracking-tight">{formatVND(amount)}</div>
      {subtitle && <div className="text-xs text-slate-400 mt-1">{subtitle}</div>}
    </div>
  );
};
