import React, { useState, useRef, useEffect } from 'react';
import { RefreshCw, CheckCircle2, AlertCircle, Cloud, ArrowUpRight } from 'lucide-react';
import { useFinance } from '../contexts/FinanceContext';
import { Button } from './ui';

export const SyncStatusPopover: React.FC = () => {
  const { syncStatus, syncNow } = useFinance();
  const [isOpen, setIsOpen] = useState(false);
  const popoverRef = useRef<HTMLDivElement>(null);

  useEffect(() => {
    const handleClickOutside = (e: MouseEvent) => {
      if (popoverRef.current && !popoverRef.current.contains(e.target as Node)) {
        setIsOpen(false);
      }
    };
    if (isOpen) {
      document.addEventListener('mousedown', handleClickOutside);
    }
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, [isOpen]);

  const handleSync = async () => {
    try {
      await syncNow();
    } catch (err) {
      console.warn('Manual sync triggered error:', err);
    }
  };

  const formatLastSync = (iso: string | null) => {
    if (!iso) return 'Chưa đồng bộ';
    const date = new Date(iso);
    return date.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit', second: '2-digit' }) + ' ' + date.toLocaleDateString('vi-VN');
  };

  return (
    <div className="relative" ref={popoverRef}>
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-medium bg-slate-100 dark:bg-slate-800/80 hover:bg-slate-200 dark:hover:bg-slate-700/80 text-slate-700 dark:text-slate-300 transition-colors cursor-pointer border border-slate-200/60 dark:border-slate-700/60"
        title="Trạng thái đồng bộ"
      >
        {syncStatus.isSyncing ? (
          <>
            <RefreshCw className="w-3.5 h-3.5 text-teal-600 dark:text-teal-400 animate-spin" />
            <span className="hidden sm:inline text-teal-600 dark:text-teal-400">Đang đồng bộ...</span>
          </>
        ) : syncStatus.error ? (
          <>
            <AlertCircle className="w-3.5 h-3.5 text-rose-500" />
            <span className="hidden sm:inline text-rose-500">Lỗi sync</span>
          </>
        ) : syncStatus.pendingCount > 0 ? (
          <>
            <ArrowUpRight className="w-3.5 h-3.5 text-amber-500" />
            <span className="hidden sm:inline text-amber-600 dark:text-amber-400">{syncStatus.pendingCount} chưa sync</span>
          </>
        ) : (
          <>
            {syncStatus.streamStatus === 'connected' ? (
              <span className="relative flex h-2 w-2 mr-0.5">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
              </span>
            ) : (
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500" />
            )}
            <span className="hidden sm:inline text-slate-600 dark:text-slate-400">
              {syncStatus.streamStatus === 'connected' ? 'Live Sync' : 'Đã đồng bộ'}
            </span>
          </>
        )}
      </button>

      {isOpen && (
        <div className="absolute right-0 mt-2 w-72 bg-white dark:bg-slate-900 border border-slate-200 dark:border-slate-800 rounded-2xl shadow-xl p-4 z-50 animate-in fade-in zoom-in-95 duration-100">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
            <div className="flex items-center gap-2">
              <Cloud className="w-4 h-4 text-teal-600 dark:text-teal-400" />
              <span className="text-sm font-semibold text-slate-900 dark:text-slate-100">Đồng bộ đám mây</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className={`inline-block w-2 h-2 rounded-full ${
                syncStatus.streamStatus === 'connected' ? 'bg-emerald-500 animate-pulse' :
                syncStatus.streamStatus === 'reconnecting' || syncStatus.streamStatus === 'connecting' ? 'bg-amber-500' :
                'bg-slate-400'
              }`} />
              <span className="text-[11px] font-medium text-slate-500 dark:text-slate-400 capitalize">
                {syncStatus.streamStatus === 'connected' ? 'Live SSE' :
                 syncStatus.streamStatus === 'reconnecting' ? 'Đang kết nối lại' :
                 syncStatus.streamStatus === 'connecting' ? 'Đang kết nối' : 'Ngoại tuyến'}
              </span>
            </div>
          </div>

          <div className="py-3 space-y-2 text-xs">
            <div className="flex justify-between text-slate-600 dark:text-slate-400">
              <span>Trạng thái Live:</span>
              <span className="font-medium text-slate-900 dark:text-slate-200">
                {syncStatus.streamStatus === 'connected' ? 'Trực tiếp (SSE)' : 'Ngoại tuyến'}
              </span>
            </div>
            <div className="flex justify-between text-slate-600 dark:text-slate-400">
              <span>Lần sync cuối:</span>
              <span className="font-medium text-slate-900 dark:text-slate-200">{formatLastSync(syncStatus.lastSyncedTime)}</span>
            </div>
            <div className="flex justify-between text-slate-600 dark:text-slate-400">
              <span>Thay đổi chưa sync:</span>
              <span className="font-medium text-slate-900 dark:text-slate-200">{syncStatus.pendingCount} mục</span>
            </div>
            {syncStatus.error && (
              <div className="p-2 rounded-lg bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 text-xs mt-2">
                {syncStatus.error}
              </div>
            )}
          </div>

          <div className="pt-2 border-t border-slate-100 dark:border-slate-800">
            <Button
              size="sm"
              className="w-full"
              isLoading={syncStatus.isSyncing}
              onClick={handleSync}
            >
              <RefreshCw className="w-3.5 h-3.5 mr-1.5" />
              Đồng bộ ngay
            </Button>
          </div>
        </div>
      )}
    </div>
  );
};
