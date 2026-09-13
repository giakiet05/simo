import React, { useState, useEffect } from 'react';
import { Modal, Input, Button, Select } from './ui';
import { useFinance } from '../contexts/FinanceContext';

interface WalletTransferModalProps {
  isOpen: boolean;
  onClose: () => void;
}

export const WalletTransferModal: React.FC<WalletTransferModalProps> = ({
  isOpen,
  onClose,
}) => {
  const { wallets, transferFunds } = useFinance();

  const [fromWalletId, setFromWalletId] = useState('');
  const [toWalletId, setToWalletId] = useState('');
  const [amount, setAmount] = useState('');
  const [fee, setFee] = useState('');
  const [date, setDate] = useState('');
  const [note, setNote] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (wallets.length >= 2) {
      setFromWalletId(wallets[0].cloud_id);
      setToWalletId(wallets[1].cloud_id);
    } else if (wallets.length === 1) {
      setFromWalletId(wallets[0].cloud_id);
      setToWalletId('');
    }
    setAmount('');
    setFee('0');
    const now = new Date();
    now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
    setDate(now.toISOString().substring(0, 16));
    setNote('');
    setError(null);
  }, [isOpen, wallets]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!fromWalletId || !toWalletId) {
      setError('Vui lòng chọn cả ví nguồn và ví đích');
      return;
    }

    if (fromWalletId === toWalletId) {
      setError('Ví nguồn và ví đích không được trùng nhau');
      return;
    }

    const numAmount = parseFloat(amount.replace(/,/g, ''));
    if (isNaN(numAmount) || numAmount <= 0) {
      setError('Vui lòng nhập số tiền chuyển hợp lệ');
      return;
    }

    const numFee = parseFloat(fee.replace(/,/g, '')) || 0;

    setIsSubmitting(true);
    setError(null);

    try {
      await transferFunds({
        from_wallet_id: fromWalletId,
        to_wallet_id: toWalletId,
        amount: numAmount,
        fee: numFee,
        date: new Date(date).toISOString(),
        note: note.trim() || undefined,
      });
      onClose();
    } catch (err: any) {
      setError(err.message || 'Lỗi khi chuyển tiền');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Chuyển tiền giữa các ví"
      maxWidth="md"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-2 gap-3">
          <Select
            label="Từ ví (Nguồn) *"
            value={fromWalletId}
            onChange={(e) => setFromWalletId(e.target.value)}
            required
          >
            {wallets.map((w) => (
              <option key={w.cloud_id} value={w.cloud_id}>
                {w.name} ({new Intl.NumberFormat('vi-VN').format(w.balance)})
              </option>
            ))}
          </Select>
          <Select
            label="Đến ví (Đích) *"
            value={toWalletId}
            onChange={(e) => setToWalletId(e.target.value)}
            required
          >
            {wallets.map((w) => (
              <option key={w.cloud_id} value={w.cloud_id}>
                {w.name} ({new Intl.NumberFormat('vi-VN').format(w.balance)})
              </option>
            ))}
          </Select>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <Input
            label="Số tiền chuyển *"
            type="number"
            step="any"
            placeholder="0"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            required
            autoFocus
          />
          <Input
            label="Phí chuyển khoản (nếu có)"
            type="number"
            step="any"
            placeholder="0"
            value={fee}
            onChange={(e) => setFee(e.target.value)}
          />
        </div>

        <Input
          label="Thời gian chuyển *"
          type="datetime-local"
          value={date}
          onChange={(e) => setDate(e.target.value)}
          required
        />

        <Input
          label="Ghi chú chuyển khoản"
          placeholder="Ví dụ: Rút tiền ATM về ví..."
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />

        {error && <p className="text-xs text-rose-500">{error}</p>}

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="outline" className="flex-1" onClick={onClose}>
            Hủy
          </Button>
          <Button type="submit" variant="primary" className="flex-1" isLoading={isSubmitting}>
            Xác nhận chuyển
          </Button>
        </div>
      </form>
    </Modal>
  );
};
