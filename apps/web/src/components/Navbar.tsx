import { useState, useRef, useEffect } from 'react';
import { Sun, Moon, Menu, LogOut } from 'lucide-react';
import { useAuth } from '../contexts/AuthContext';
import { useTheme } from '../contexts/ThemeContext';
import { SyncStatusPopover } from './SyncStatusPopover';
import type { TabId } from './Sidebar';

interface NavbarProps {
  activeTab: TabId;
  onToggleMobileMenu: () => void;
}

const tabTitles: Record<TabId, string> = {
  dashboard: 'Tổng quan tài chính',
  transactions: 'Sổ ghi chép giao dịch',
  wallets: 'Quản lý tài khoản & Ví',
  budgets: 'Ngân sách chi tiêu',
  'saving-goals': 'Mục tiêu tích lũy',
  loans: 'Sổ theo dõi nợ & Cho vay',
  recurring: 'Thiết lập giao dịch định kỳ',
  reports: 'Báo cáo & Phân tích chuyên sâu',
  'export-backup': 'Xuất báo cáo & Sao lưu JSON',
  settings: 'Cài đặt hệ thống',
};

export const Navbar: React.FC<NavbarProps> = ({ activeTab, onToggleMobileMenu }) => {
  const { user, logout } = useAuth();
  const { resolvedTheme, toggleTheme } = useTheme();
  const [isProfileOpen, setIsProfileOpen] = useState(false);
  const profileRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (profileRef.current && !profileRef.current.contains(e.target as Node)) {
        setIsProfileOpen(false);
      }
    };
    if (isProfileOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isProfileOpen]);

  return (
    <header className="h-16 bg-white dark:bg-slate-900 border-b border-slate-200/80 dark:border-slate-800 flex items-center justify-between px-4 sm:px-8 sticky top-0 z-30 transition-colors duration-150">
      {/* Left side: Mobile Menu toggle + Active Title */}
      <div className="flex items-center gap-3">
        <button
          onClick={onToggleMobileMenu}
          className="md:hidden p-2 rounded-xl text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors cursor-pointer"
          title="Mở menu"
        >
          <Menu className="w-5 h-5" />
        </button>
        <div>
          <h2 className="text-base sm:text-lg font-bold text-slate-900 dark:text-slate-100 tracking-tight">
            {tabTitles[activeTab]}
          </h2>
        </div>
      </div>

      {/* Right side: Sync status + Theme toggle + User Profile */}
      <div className="flex items-center gap-2 sm:gap-3">
        {/* Sync Status */}
        <SyncStatusPopover />

        {/* Theme Switcher */}
        <button
          onClick={toggleTheme}
          className="p-2 rounded-xl text-slate-600 dark:text-slate-300 hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors cursor-pointer"
          title={resolvedTheme === 'dark' ? 'Chuyển sang Giao diện sáng (Nền trắng)' : 'Chuyển sang Giao diện tối'}
        >
          {resolvedTheme === 'dark' ? (
            <Sun className="w-4 h-4 text-amber-400" />
          ) : (
            <Moon className="w-4 h-4 text-slate-600" />
          )}
        </button>

        {/* User Profile */}
        <div className="relative" ref={profileRef}>
          <button
            onClick={() => setIsProfileOpen(!isProfileOpen)}
            className="flex items-center gap-2 p-1.5 rounded-xl hover:bg-slate-100 dark:hover:bg-slate-800 transition-colors cursor-pointer"
          >
            {user?.avatar_url ? (
              <img
                src={user.avatar_url}
                alt={user.display_name || user.email}
                className="w-7 h-7 rounded-full object-cover ring-1 ring-slate-200 dark:ring-slate-700"
              />
            ) : (
              <div className="w-7 h-7 rounded-full bg-teal-600 text-white flex items-center justify-center font-bold text-xs">
                {(user?.display_name || user?.email || 'U').charAt(0).toUpperCase()}
              </div>
            )}
            <span className="hidden lg:inline text-xs font-semibold text-slate-700 dark:text-slate-200 max-w-[120px] truncate">
              {user?.display_name || user?.email?.split('@')[0]}
            </span>
          </button>

          {isProfileOpen && (
            <div className="absolute right-0 mt-2 w-56 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-xl p-2 z-50 animate-in fade-in zoom-in-95 duration-100">
              <div className="px-3 py-2 border-b border-slate-100 dark:border-slate-800">
                <p className="text-xs font-semibold text-slate-900 dark:text-slate-100 truncate">
                  {user?.display_name || 'Người dùng'}
                </p>
                <p className="text-[11px] text-slate-500 dark:text-slate-400 truncate mt-0.5">
                  {user?.email}
                </p>
              </div>
              <div className="pt-1">
                <button
                  onClick={() => {
                    setIsProfileOpen(false);
                    logout();
                  }}
                  className="w-full flex items-center gap-2 px-3 py-2 text-xs font-medium text-rose-600 dark:text-rose-400 hover:bg-rose-50 dark:hover:bg-rose-950/40 rounded-xl transition-colors cursor-pointer"
                >
                  <LogOut className="w-4 h-4" />
                  <span>Đăng xuất</span>
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </header>
  );
};
