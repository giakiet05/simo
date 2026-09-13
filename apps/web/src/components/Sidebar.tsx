import React from 'react';
import {
  LayoutDashboard,
  ReceiptText,
  WalletCards,
  PieChart,
  Target,
  HandCoins,
  Repeat,
  BarChart3,
  FileSpreadsheet,
  Settings,
  PlusCircle,
  ArrowLeftRight,
} from 'lucide-react';
import { cn } from './ui';

export type TabId =
  | 'dashboard'
  | 'transactions'
  | 'wallets'
  | 'budgets'
  | 'saving-goals'
  | 'loans'
  | 'recurring'
  | 'reports'
  | 'export-backup'
  | 'settings';

interface SidebarProps {
  activeTab: TabId;
  onTabChange: (tab: TabId) => void;
  onOpenNewTransaction: () => void;
  onOpenTransfer: () => void;
  className?: string;
}

export const navigationItems: Array<{ id: TabId; label: string; icon: React.ElementType; section?: string }> = [
  { id: 'dashboard', label: 'Tổng quan', icon: LayoutDashboard },
  { id: 'transactions', label: 'Sổ giao dịch', icon: ReceiptText },
  { id: 'wallets', label: 'Tài khoản & Ví', icon: WalletCards },
  { id: 'budgets', label: 'Ngân sách', icon: PieChart },
  { id: 'saving-goals', label: 'Mục tiêu tích lũy', icon: Target },
  { id: 'loans', label: 'Sổ nợ (Vay / Mượn)', icon: HandCoins },
  { id: 'recurring', label: 'Giao dịch định kỳ', icon: Repeat },
  { id: 'reports', label: 'Báo cáo & Thống kê', icon: BarChart3 },
  { id: 'export-backup', label: 'Xuất & Sao lưu', icon: FileSpreadsheet },
  { id: 'settings', label: 'Cài đặt', icon: Settings },
];

export const Sidebar: React.FC<SidebarProps> = ({
  activeTab,
  onTabChange,
  onOpenNewTransaction,
  onOpenTransfer,
  className,
}) => {
  return (
    <aside
      className={cn(
        'w-64 bg-white dark:bg-slate-900 border-r border-slate-200/80 dark:border-slate-800 flex flex-col shrink-0 h-screen sticky top-0 transition-colors duration-150',
        className
      )}
    >
      {/* Brand Header */}
      <div className="h-16 flex items-center px-6 border-b border-slate-100 dark:border-slate-800/80 gap-3">
        <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-teal-600 to-emerald-400 flex items-center justify-center shadow-xs">
          <span className="text-white font-bold text-lg tracking-wider">S</span>
        </div>
        <div>
          <h1 className="font-bold text-base text-slate-900 dark:text-slate-100 tracking-tight">Simo Finance</h1>
          <p className="text-[10px] text-teal-600 dark:text-teal-400 font-medium">Personal Ledger</p>
        </div>
      </div>

      {/* Quick Action Buttons */}
      <div className="p-4 space-y-2">
        <button
          onClick={onOpenNewTransaction}
          className="w-full flex items-center justify-center gap-2 py-2.5 px-4 bg-teal-600 hover:bg-teal-700 text-white rounded-xl text-sm font-semibold shadow-xs hover:shadow transition-all duration-150 cursor-pointer active:scale-[0.99]"
        >
          <PlusCircle className="w-4 h-4" />
          <span>Thêm giao dịch</span>
        </button>
        <button
          onClick={onOpenTransfer}
          className="w-full flex items-center justify-center gap-2 py-2 px-4 bg-slate-100 dark:bg-slate-800 hover:bg-slate-200 dark:hover:bg-slate-700/80 text-slate-700 dark:text-slate-300 rounded-xl text-xs font-medium transition-colors cursor-pointer"
        >
          <ArrowLeftRight className="w-3.5 h-3.5" />
          <span>Chuyển tiền ví</span>
        </button>
      </div>

      {/* Navigation List */}
      <nav className="flex-1 px-3 py-2 space-y-1 overflow-y-auto">
        {navigationItems.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.id;
          return (
            <button
              key={item.id}
              onClick={() => onTabChange(item.id)}
              className={cn(
                'w-full flex items-center gap-3 px-3.5 py-2.5 rounded-xl text-sm font-medium transition-all duration-150 cursor-pointer',
                isActive
                  ? 'bg-teal-50 dark:bg-teal-950/40 text-teal-700 dark:text-teal-300 font-semibold shadow-xs'
                  : 'text-slate-600 dark:text-slate-400 hover:bg-slate-50 dark:hover:bg-slate-800/60 hover:text-slate-900 dark:hover:text-slate-200'
              )}
            >
              <Icon className={cn('w-4 h-4 shrink-0', isActive ? 'text-teal-600 dark:text-teal-400' : 'text-slate-400 dark:text-slate-500')} />
              <span className="truncate">{item.label}</span>
            </button>
          );
        })}
      </nav>

      {/* Footer info */}
      <div className="p-4 border-t border-slate-100 dark:border-slate-800/80 text-[11px] text-slate-400 dark:text-slate-500 flex justify-between items-center">
        <span>Simo Web v1.2</span>
        <span className="px-2 py-0.5 rounded-md bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400 text-[10px]">1:1 Parity</span>
      </div>
    </aside>
  );
};
