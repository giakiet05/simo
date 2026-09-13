import React, { useState, useEffect } from 'react';
import { Modal, Input, Button, Select } from './ui';
import { useFinance } from '../contexts/FinanceContext';
import type { RecurringConfig, RecurringFrequency } from '../types';

interface RecurringModalProps {
  isOpen: boolean;
  onClose: () => void;
  editingConfig?: RecurringConfig | null;
}

export const RecurringModal: React.FC<RecurringModalProps> = ({
  isOpen,
  onClose,
  editingConfig,
}) => {
  const { categories, wallets, addRecurringConfig, updateRecurringConfig } = useFinance();

  const [frequency, setFrequency] = useState<RecurringFrequency>('monthly');
  const [amount, setAmount] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [walletId, setWalletId] = useState('');
  const [startDate, setStartDate] = useState('');
  const [nextRunDate, setNextRunDate] = useState('');
  const [note, setNote] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (editingConfig) {
      setFrequency(editingConfig.frequency);
      setAmount(editingConfig.amount.toString());
      setCategoryId(editingConfig.category_id || '');
      setWalletId(editingConfig.wallet_id || '');
      setStartDate(editingConfig.start_date || '');
      setNextRunDate(editingConfig.next_run_date || '');
      setNote(editingConfig.note || '');
    } else {
      setFrequency('monthly');
      setAmount('');
      const firstCat = categories[0];
      setCategoryId(firstCat ? firstCat.cloud_id : '');
      const defWallet = wallets.find((w) => w.is_default) || wallets[0];
      setWalletId(defWallet ? defWallet.cloud_id : '');
      const today = new Date().toISOString().split('T')[0];
      setStartDate(today);
      setNextRunDate(today);
      setNote('');
    }
    setError(null);
  }, [editingConfig, isOpen, categories, wallets]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const numAmount = parseFloat(amount.replace(/,/g, ''));
    if (isNaN(numAmount) || numAmount <= 0) {
      setError('Vui lòng nhập số tiền hợp lệ');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      if (editingConfig) {
        await updateRecurringConfig(editingConfig.cloud_id, {
          frequency,
          amount: numAmount,
          category_id: categoryId || undefined,
          wallet_id: walletId || undefined,
          start_date: startDate,
          next_run_date: nextRunDate,
          note: note.trim() || undefined,
        });
      } else {
        await addRecurringConfig({
          frequency,
          amount: numAmount,
          category_id: categoryId || undefined,
          wallet_id: walletId || undefined,
          start_date: startDate,
          next_run_date: nextRunDate,
          note: note.trim() || undefined,
        });
      }
      onClose();
    } catch (err: any) {
      setError(err.message || 'Lỗi khi lưu giao dịch định kỳ');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={editingConfig ? 'Chỉnh sửa giao dịch định kỳ' : 'Tạo giao dịch định kỳ mới'}
      maxWidth="md"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-2 gap-3">
          <Select
            label="Tần suất lặp lại *"
            value={frequency}
            onChange={(e) => setFrequency(e.target.value as RecurringFrequency)}
          >
            <option value="daily">Hàng ngày (Daily)</option>
            <option value="weekly">Hàng tuần (Weekly)</option>
            <option value="monthly">Hàng tháng (Monthly)</option>
            <option value="yearly">Hàng năm (Yearly)</option>
          </Select>

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

        <div className="grid grid-cols-2 gap-3">
          <Select
            label="Danh mục"
            value={categoryId}
            onChange={(e) => setCategoryId(e.target.value)}
          >
            <option value="">-- Chọn danh mục --</option>
            {categories.map((c) => (
              <option key={c.cloud_id} value={c.cloud_id}>
                {c.name}
              </option>
            ))}
          </Select>

          <Select
            label="Tài khoản / Ví *"
            value={walletId}
            onChange={(e) => setWalletId(e.target.value)}
          >
            <option value="">-- Chọn ví --</option>
            {wallets.map((w) => (
              <option key={w.cloud_id} value={w.cloud_id}>
                {w.name}
              </option>
            ))}
          </Select>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <Input
            label="Ngày bắt đầu *"
            type="date"
            value={startDate}
            onChange={(e) => setStartDate(e.target.value)}
            required
          />
          <Input
            label="Ngày thực thi tiếp theo *"
            type="date"
            value={nextRunDate}
            onChange={(e) => setNextRunDate(e.target.value)}
            required
          />
        </div>

        <Input
          label="Mô tả / Ghi chú"
          placeholder="Ví dụ: Tiền thuê nhà, Tiền mạng Internet, Đóng bảo hiểm..."
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />

        {error && <p className="text-xs text-rose-500">{error}</p>}

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="outline" className="flex-1" onClick={onClose}>
            Hủy
          </Button>
          <Button type="submit" variant="primary" className="flex-1" isLoading={isSubmitting}>
            {editingConfig ? 'Lưu thay đổi' : 'Tạo lịch định kỳ'}
          </Button>
        </div>
      </form>
    </Modal>
  );
};
