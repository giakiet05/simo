import React, { useState, useEffect } from 'react';
import { Modal, Input, Button, Select } from './ui';
import { useFinance } from '../contexts/FinanceContext';
import type { Transaction, TransactionType } from '../types';

interface TransactionModalProps {
  isOpen: boolean;
  onClose: () => void;
  editingTransaction?: Transaction | null;
}

export const TransactionModal: React.FC<TransactionModalProps> = ({
  isOpen,
  onClose,
  editingTransaction,
}) => {
  const { wallets, categories, addTransaction, updateTransaction } = useFinance();

  const [type, setType] = useState<TransactionType>('expense');
  const [amount, setAmount] = useState<string>('');
  const [walletId, setWalletId] = useState<string>('');
  const [categoryId, setCategoryId] = useState<string>('');
  const [date, setDate] = useState<string>('');
  const [note, setNote] = useState<string>('');
  const [isSubmitting, setIsSubmitting] = useState<boolean>(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (editingTransaction) {
      setType(editingTransaction.type);
      setAmount(editingTransaction.amount.toString());
      setWalletId(editingTransaction.wallet_id || '');
      setCategoryId(editingTransaction.category_id || '');
      setDate(
        editingTransaction.date ? editingTransaction.date.substring(0, 16) : new Date().toISOString().substring(0, 16)
      );
      setNote(editingTransaction.note || '');
    } else {
      setType('expense');
      setAmount('');
      const defaultW = wallets.find((w) => w.is_default) || wallets[0];
      setWalletId(defaultW ? defaultW.cloud_id : '');
      const firstCat = categories.find((c) => c.type === 'expense');
      setCategoryId(firstCat ? firstCat.cloud_id : '');
      const now = new Date();
      now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
      setDate(now.toISOString().substring(0, 16));
      setNote('');
    }
    setError(null);
  }, [editingTransaction, isOpen, wallets, categories]);

  const filteredCategories = categories.filter((c) => {
    if (type === 'expense') return c.type === 'expense';
    if (type === 'income') return c.type === 'income';
    return true;
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const numAmount = parseFloat(amount.replace(/,/g, ''));
    if (isNaN(numAmount) || numAmount <= 0) {
      setError('Vui lòng nhập số tiền hợp lệ lớn hơn 0');
      return;
    }

    if (!walletId && wallets.length > 0) {
      setError('Vui lòng chọn ví thanh toán');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      if (editingTransaction) {
        await updateTransaction(editingTransaction.cloud_id, {
          type,
          amount: numAmount,
          wallet_id: walletId || undefined,
          category_id: categoryId || undefined,
          date: new Date(date).toISOString(),
          note: note.trim() || undefined,
        });
      } else {
        await addTransaction({
          type,
          amount: numAmount,
          wallet_id: walletId || undefined,
          category_id: categoryId || undefined,
          date: new Date(date).toISOString(),
          note: note.trim() || undefined,
        });
      }
      onClose();
    } catch (err: any) {
      setError(err.message || 'Lỗi khi lưu giao dịch');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={editingTransaction ? 'Chỉnh sửa giao dịch' : 'Thêm giao dịch mới'}
      maxWidth="md"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        {/* Type Selector */}
        <div className="grid grid-cols-2 gap-2 p-1 bg-slate-100 dark:bg-slate-800 rounded-xl">
          <button
            type="button"
            onClick={() => {
              setType('expense');
              const firstExp = categories.find((c) => c.type === 'expense');
              if (firstExp) setCategoryId(firstExp.cloud_id);
            }}
            className={`py-2 text-xs font-semibold rounded-lg transition-all cursor-pointer ${
              type === 'expense'
                ? 'bg-rose-500 text-white shadow-xs'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900'
            }`}
          >
            Chi tiêu (Expense)
          </button>
          <button
            type="button"
            onClick={() => {
              setType('income');
              const firstInc = categories.find((c) => c.type === 'income');
              if (firstInc) setCategoryId(firstInc.cloud_id);
            }}
            className={`py-2 text-xs font-semibold rounded-lg transition-all cursor-pointer ${
              type === 'income'
                ? 'bg-emerald-500 text-white shadow-xs'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900'
            }`}
          >
            Thu nhập (Income)
          </button>
        </div>

        {/* Amount */}
        <div>
          <Input
            label="Số tiền *"
            type="number"
            step="any"
            placeholder="0"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            required
            autoFocus
          />
        </div>

        {/* Category Picker */}
        <div>
          <Select
            label="Danh mục chi tiêu / thu nhập"
            value={categoryId}
            onChange={(e) => setCategoryId(e.target.value)}
          >
            <option value="">-- Không có danh mục --</option>
            {filteredCategories.map((c) => (
              <option key={c.cloud_id} value={c.cloud_id}>
                {c.name}
              </option>
            ))}
          </Select>
        </div>

        {/* Wallet Picker */}
        <div>
          <Select
            label="Tài khoản / Ví *"
            value={walletId}
            onChange={(e) => setWalletId(e.target.value)}
            required
          >
            {wallets.map((w) => (
              <option key={w.cloud_id} value={w.cloud_id}>
                {w.name} ({new Intl.NumberFormat('vi-VN').format(w.balance)} {w.currency})
              </option>
            ))}
          </Select>
        </div>

        {/* Date & Time */}
        <div>
          <Input
            label="Thời gian giao dịch *"
            type="datetime-local"
            value={date}
            onChange={(e) => setDate(e.target.value)}
            required
          />
        </div>

        {/* Note */}
        <div>
          <Input
            label="Ghi chú / Diễn giải"
            placeholder="Ví dụ: Ăn trưa tại quán cơm tấm..."
            value={note}
            onChange={(e) => setNote(e.target.value)}
          />
        </div>

        {error && <p className="text-xs text-rose-500">{error}</p>}

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="outline" className="flex-1" onClick={onClose}>
            Hủy
          </Button>
          <Button type="submit" variant="primary" className="flex-1" isLoading={isSubmitting}>
            {editingTransaction ? 'Cập nhật' : 'Thêm giao dịch'}
          </Button>
        </div>
      </form>
    </Modal>
  );
};
