import { useState, useMemo } from 'react';
import {
  Plus,
  Trash2,
  Tag,
  Calendar,
  Wallet as WalletIcon,
  CheckSquare,
  Square,
  Edit2,
  FileSpreadsheet,
} from 'lucide-react';
import { useFinance } from '../contexts/FinanceContext';
import { Button, Card, Modal } from '../components/ui';
import { TransactionFilterBar } from '../components/TransactionFilterBar';
import { exportService } from '../services/exportService';
import type { Transaction, TransactionFilterCriteria } from '../types';

interface TransactionsPageProps {
  onOpenNewTransaction: () => void;
  onEditTransaction: (tx: Transaction) => void;
}

export const TransactionsPage: React.FC<TransactionsPageProps> = ({
  onOpenNewTransaction,
  onEditTransaction,
}) => {
  const {
    categories,
    wallets,
    deleteTransaction,
    bulkDeleteTransactions,
    bulkUpdateCategory,
    bulkUpdateDate,
    bulkUpdateWallet,
    filterTransactions,
  } = useFinance();

  const [filterCriteria, setFilterCriteria] = useState<TransactionFilterCriteria>({});
  const [selectedIds, setSelectedIds] = useState<string[]>([]);
  const [bulkCategoryModalOpen, setBulkCategoryModalOpen] = useState(false);
  const [bulkDateModalOpen, setBulkDateModalOpen] = useState(false);
  const [bulkWalletModalOpen, setBulkWalletModalOpen] = useState(false);
  const [targetCategory, setTargetCategory] = useState('');
  const [targetDate, setTargetDate] = useState('');
  const [targetWallet, setTargetWallet] = useState('');

  const catMap = useMemo(() => new Map(categories.map((c) => [c.cloud_id, c])), [categories]);
  const walletMap = useMemo(() => new Map(wallets.map((w) => [w.cloud_id, w])), [wallets]);

  const filteredList = useMemo(() => {
    return filterTransactions(filterCriteria);
  }, [filterTransactions, filterCriteria]);

  // Group transactions by date (YYYY-MM-DD)
  const groupedTransactions = useMemo(() => {
    const groups: { [dateStr: string]: { date: string; items: Transaction[]; dayIncome: number; dayExpense: number } } = {};

    filteredList.forEach((tx) => {
      const dateKey = tx.date ? tx.date.split('T')[0] : 'Chưa rõ ngày';
      if (!groups[dateKey]) {
        groups[dateKey] = { date: dateKey, items: [], dayIncome: 0, dayExpense: 0 };
      }
      groups[dateKey].items.push(tx);
      if (tx.type === 'income') groups[dateKey].dayIncome += Number(tx.amount);
      if (tx.type === 'expense') groups[dateKey].dayExpense += Number(tx.amount);
    });

    return Object.values(groups).sort((a, b) => b.date.localeCompare(a.date));
  }, [filteredList]);

  const handleToggleSelectAll = () => {
    if (selectedIds.length === filteredList.length) {
      setSelectedIds([]);
    } else {
      setSelectedIds(filteredList.map((t) => t.cloud_id));
    }
  };

  const handleToggleSelect = (cloudId: string) => {
    if (selectedIds.includes(cloudId)) {
      setSelectedIds(selectedIds.filter((id) => id !== cloudId));
    } else {
      setSelectedIds([...selectedIds, cloudId]);
    }
  };

  const handleBulkDelete = async () => {
    if (confirm(`Bạn có chắc muốn xóa ${selectedIds.length} giao dịch đã chọn?`)) {
      await bulkDeleteTransactions(selectedIds);
      setSelectedIds([]);
    }
  };

  const handleBulkApplyCategory = async () => {
    if (!targetCategory) return;
    await bulkUpdateCategory(selectedIds, targetCategory);
    setSelectedIds([]);
    setBulkCategoryModalOpen(false);
  };

  const handleBulkApplyDate = async () => {
    if (!targetDate) return;
    await bulkUpdateDate(selectedIds, new Date(targetDate).toISOString());
    setSelectedIds([]);
    setBulkDateModalOpen(false);
  };

  const handleBulkApplyWallet = async () => {
    if (!targetWallet) return;
    await bulkUpdateWallet(selectedIds, targetWallet);
    setSelectedIds([]);
    setBulkWalletModalOpen(false);
  };

  const formatDateLabel = (dateStr: string) => {
    const today = new Date().toISOString().split('T')[0];
    const yesterday = new Date(Date.now() - 86400000).toISOString().split('T')[0];
    if (dateStr === today) return 'Hôm nay';
    if (dateStr === yesterday) return 'Hôm qua';
    const parts = dateStr.split('-');
    if (parts.length === 3) return `${parts[2]}/${parts[1]}/${parts[0]}`;
    return dateStr;
  };

  return (
    <div className="space-y-4 animate-in fade-in duration-200">
      {/* Header & Quick Action */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-slate-900 dark:text-slate-100 tracking-tight">
            Sổ ghi chép giao dịch
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Tổng số: <span className="font-semibold text-slate-700 dark:text-slate-300">{filteredList.length}</span> giao dịch
          </p>
        </div>
        <div className="flex items-center gap-2">
          {filteredList.length > 0 && (
            <Button size="sm" variant="secondary" onClick={handleToggleSelectAll}>
              <CheckSquare className="w-3.5 h-3.5" />
              <span>{selectedIds.length === filteredList.length ? 'Bỏ chọn' : 'Chọn tất cả'}</span>
            </Button>
          )}
          <Button
            size="sm"
            variant="outline"
            onClick={() => exportService.exportToCSV(filteredList, categories, wallets)}
          >
            <FileSpreadsheet className="w-3.5 h-3.5" />
            <span>Xuất CSV</span>
          </Button>
          <Button size="sm" variant="primary" onClick={onOpenNewTransaction}>
            <Plus className="w-3.5 h-3.5" />
            <span>Thêm giao dịch</span>
          </Button>
        </div>
      </div>

      {/* Advanced Filter Bar */}
      <TransactionFilterBar criteria={filterCriteria} onChange={setFilterCriteria} />

      {/* Bulk Action Toolbar */}
      {selectedIds.length > 0 && (
        <div className="flex items-center justify-between p-3 bg-teal-50 dark:bg-teal-950/40 border border-teal-200 dark:border-teal-800 rounded-2xl animate-in slide-in-from-top-2">
          <div className="flex items-center gap-2 text-xs font-semibold text-teal-800 dark:text-teal-200">
            <CheckSquare className="w-4 h-4 text-teal-600 dark:text-teal-400" />
            <span>Đã chọn {selectedIds.length} giao dịch</span>
          </div>
          <div className="flex items-center gap-2">
            <Button size="sm" variant="secondary" onClick={() => setBulkCategoryModalOpen(true)}>
              <Tag className="w-3.5 h-3.5" />
              <span>Đổi danh mục</span>
            </Button>
            <Button size="sm" variant="secondary" onClick={() => setBulkDateModalOpen(true)}>
              <Calendar className="w-3.5 h-3.5" />
              <span>Đổi ngày</span>
            </Button>
            <Button size="sm" variant="secondary" onClick={() => setBulkWalletModalOpen(true)}>
              <WalletIcon className="w-3.5 h-3.5" />
              <span>Đổi ví</span>
            </Button>
            <Button size="sm" variant="danger" onClick={handleBulkDelete}>
              <Trash2 className="w-3.5 h-3.5" />
              <span>Xóa</span>
            </Button>
          </div>
        </div>
      )}

      {/* Grouped Transactions List */}
      <div className="space-y-4">
        {groupedTransactions.length === 0 ? (
          <Card className="py-12 text-center text-slate-400 space-y-3">
            <p className="text-sm">Không tìm thấy giao dịch nào phù hợp với bộ lọc</p>
            <Button size="sm" variant="primary" onClick={onOpenNewTransaction}>
              Thêm giao dịch mới
            </Button>
          </Card>
        ) : (
          groupedTransactions.map((group) => (
            <div key={group.date} className="space-y-2">
              {/* Date Header with Day Subtotals */}
              <div className="flex items-center justify-between px-2 text-xs">
                <div className="flex items-center gap-2">
                  <span className="font-bold text-slate-900 dark:text-slate-100">
                    {formatDateLabel(group.date)}
                  </span>
                  <span className="text-slate-400">({group.items.length})</span>
                </div>
                <div className="flex items-center gap-3 text-[11px] font-semibold">
                  {group.dayIncome > 0 && (
                    <span className="text-emerald-600 dark:text-emerald-400">
                      +{new Intl.NumberFormat('vi-VN').format(group.dayIncome)} ₫
                    </span>
                  )}
                  {group.dayExpense > 0 && (
                    <span className="text-rose-600 dark:text-rose-400">
                      -{new Intl.NumberFormat('vi-VN').format(group.dayExpense)} ₫
                    </span>
                  )}
                </div>
              </div>

              {/* Transactions in Group */}
              <Card className="p-0 overflow-hidden divide-y divide-slate-100 dark:divide-slate-800/80">
                {group.items.map((tx) => {
                  const isSelected = selectedIds.includes(tx.cloud_id);
                  const cat = catMap.get(tx.category_id || '');
                  const wal = walletMap.get(tx.wallet_id || '');

                  return (
                    <div
                      key={tx.cloud_id}
                      className={`flex items-center justify-between p-3.5 hover:bg-slate-50 dark:hover:bg-slate-800/40 transition-colors ${
                        isSelected ? 'bg-teal-50/60 dark:bg-teal-950/20' : ''
                      }`}
                    >
                      <div className="flex items-center gap-3 min-w-0">
                        <button
                          onClick={() => handleToggleSelect(tx.cloud_id)}
                          className="text-slate-400 hover:text-teal-600 cursor-pointer"
                        >
                          {isSelected ? (
                            <CheckSquare className="w-4 h-4 text-teal-600" />
                          ) : (
                            <Square className="w-4 h-4" />
                          )}
                        </button>

                        <div
                          className="w-9 h-9 rounded-xl flex items-center justify-center text-xs font-bold text-white shrink-0 shadow-xs"
                          style={{ backgroundColor: cat?.color || '#94A3B8' }}
                        >
                          {(cat?.name || 'K').charAt(0).toUpperCase()}
                        </div>

                        <div className="min-w-0">
                          <p className="text-xs sm:text-sm font-semibold text-slate-900 dark:text-slate-100 truncate">
                            {tx.note || cat?.name || 'Giao dịch'}
                          </p>
                          <div className="flex items-center gap-2 text-[11px] text-slate-400 mt-0.5">
                            <span>{cat?.name || 'Chưa phân loại'}</span>
                            <span>•</span>
                            <span className="text-teal-600 dark:text-teal-400 font-medium">
                              {wal?.name || 'Ví'}
                            </span>
                          </div>
                        </div>
                      </div>

                      <div className="flex items-center gap-3 shrink-0">
                        <span
                          className={`text-xs sm:text-sm font-bold ${
                            tx.type === 'income'
                              ? 'text-emerald-600 dark:text-emerald-400'
                              : 'text-rose-600 dark:text-rose-400'
                          }`}
                        >
                          {tx.type === 'income' ? '+' : '-'}
                          {new Intl.NumberFormat('vi-VN').format(tx.amount)} ₫
                        </span>

                        <div className="flex items-center gap-1">
                          <button
                            onClick={() => onEditTransaction(tx)}
                            className="p-1 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-700 cursor-pointer"
                            title="Sửa giao dịch"
                          >
                            <Edit2 className="w-3.5 h-3.5" />
                          </button>
                          <button
                            onClick={() => {
                              if (confirm('Bạn có chắc muốn xóa giao dịch này?')) {
                                deleteTransaction(tx.cloud_id);
                              }
                            }}
                            className="p-1 text-slate-400 hover:text-rose-500 rounded-lg hover:bg-rose-50 dark:hover:bg-rose-950/30 cursor-pointer"
                            title="Xóa giao dịch"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </div>
                    </div>
                  );
                })}
              </Card>
            </div>
          ))
        )}
      </div>

      {/* Bulk Category Modal */}
      <Modal
        isOpen={bulkCategoryModalOpen}
        onClose={() => setBulkCategoryModalOpen(false)}
        title="Đổi danh mục hàng loạt"
        maxWidth="sm"
      >
        <div className="space-y-4">
          <select
            value={targetCategory}
            onChange={(e) => setTargetCategory(e.target.value)}
            className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl text-sm"
          >
            <option value="">-- Chọn danh mục mới --</option>
            {categories.map((c) => (
              <option key={c.cloud_id} value={c.cloud_id}>
                {c.name}
              </option>
            ))}
          </select>
          <div className="flex gap-2">
            <Button variant="outline" className="flex-1" onClick={() => setBulkCategoryModalOpen(false)}>
              Hủy
            </Button>
            <Button variant="primary" className="flex-1" onClick={handleBulkApplyCategory}>
              Áp dụng
            </Button>
          </div>
        </div>
      </Modal>

      {/* Bulk Date Modal */}
      <Modal
        isOpen={bulkDateModalOpen}
        onClose={() => setBulkDateModalOpen(false)}
        title="Đổi ngày giao dịch hàng loạt"
        maxWidth="sm"
      >
        <div className="space-y-4">
          <input
            type="date"
            value={targetDate}
            onChange={(e) => setTargetDate(e.target.value)}
            className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl text-sm"
          />
          <div className="flex gap-2">
            <Button variant="outline" className="flex-1" onClick={() => setBulkDateModalOpen(false)}>
              Hủy
            </Button>
            <Button variant="primary" className="flex-1" onClick={handleBulkApplyDate}>
              Áp dụng
            </Button>
          </div>
        </div>
      </Modal>

      {/* Bulk Wallet Modal */}
      <Modal
        isOpen={bulkWalletModalOpen}
        onClose={() => setBulkWalletModalOpen(false)}
        title="Đổi ví hàng loạt"
        maxWidth="sm"
      >
        <div className="space-y-4">
          <select
            value={targetWallet}
            onChange={(e) => setTargetWallet(e.target.value)}
            className="w-full px-3 py-2 bg-slate-50 dark:bg-slate-800 border border-slate-200 dark:border-slate-700 rounded-xl text-sm"
          >
            <option value="">-- Chọn ví mới --</option>
            {wallets.map((w) => (
              <option key={w.cloud_id} value={w.cloud_id}>
                {w.name}
              </option>
            ))}
          </select>
          <div className="flex gap-2">
            <Button variant="outline" className="flex-1" onClick={() => setBulkWalletModalOpen(false)}>
              Hủy
            </Button>
            <Button variant="primary" className="flex-1" onClick={handleBulkApplyWallet}>
              Áp dụng
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
};
