import React, { useState, useEffect } from 'react';
import { Modal, Input, Button, Select } from './ui';
import { useFinance } from '../contexts/FinanceContext';
import type { SavingGoal } from '../types';

interface SavingGoalLogModalProps {
  isOpen: boolean;
  onClose: () => void;
  goal: SavingGoal | null;
  mode: 'deposit' | 'withdraw';
}

export const SavingGoalLogModal: React.FC<SavingGoalLogModalProps> = ({
  isOpen,
  onClose,
  goal,
  mode,
}) => {
  const { wallets, depositSavingGoal, withdrawSavingGoal } = useFinance();

  const [walletId, setWalletId] = useState('');
  const [amount, setAmount] = useState('');
  const [note, setNote] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (wallets.length > 0) {
      const def = wallets.find((w) => w.is_default) || wallets[0];
      setWalletId(def.cloud_id);
    }
    setAmount('');
    setNote('');
    setError(null);
  }, [isOpen, wallets]);

  if (!goal) return null;

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const numAmount = parseFloat(amount.replace(/,/g, ''));
    if (isNaN(numAmount) || numAmount <= 0) {
      setError('Vui lòng nhập số tiền hợp lệ');
      return;
    }
    if (!walletId) {
      setError('Vui lòng chọn ví thực hiện');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      if (mode === 'deposit') {
        await depositSavingGoal(goal.cloud_id, walletId, numAmount, note.trim() || undefined);
      } else {
        await withdrawSavingGoal(goal.cloud_id, walletId, numAmount, note.trim() || undefined);
      }
      onClose();
    } catch (err: any) {
      setError(err.message || 'Lỗi khi thực hiện giao dịch tích lũy');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={mode === 'deposit' ? `Nạp tiền vào: ${goal.name}` : `Rút tiền từ: ${goal.name}`}
      maxWidth="md"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <Select
          label="Ví nguồn / đích *"
          value={walletId}
          onChange={(e) => setWalletId(e.target.value)}
          required
        >
          {wallets.map((w) => (
            <option key={w.cloud_id} value={w.cloud_id}>
              {w.name} ({new Intl.NumberFormat('vi-VN').format(w.balance)})
            </option>
          ))}
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

        <Input
          label="Ghi chú"
          placeholder="Ví dụ: Tiết kiệm lương tháng này..."
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />

        {error && <p className="text-xs text-rose-500">{error}</p>}

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="outline" className="flex-1" onClick={onClose}>
            Hủy
          </Button>
          <Button
            type="submit"
            variant={mode === 'deposit' ? 'primary' : 'danger'}
            className="flex-1"
            isLoading={isSubmitting}
          >
            {mode === 'deposit' ? 'Xác nhận Nạp tiền' : 'Xác nhận Rút tiền'}
          </Button>
        </div>
      </form>
    </Modal>
  );
};
