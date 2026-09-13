import React, { useState, useEffect } from 'react';
import { Modal, Input, Button, Select } from './ui';
import { useFinance } from '../contexts/FinanceContext';
import type { Wallet, WalletType } from '../types';

interface WalletModalProps {
  isOpen: boolean;
  onClose: () => void;
  editingWallet?: Wallet | null;
}

export const WalletModal: React.FC<WalletModalProps> = ({
  isOpen,
  onClose,
  editingWallet,
}) => {
  const { addWallet, updateWallet } = useFinance();

  const [name, setName] = useState('');
  const [balance, setBalance] = useState('');
  const [currency, setCurrency] = useState('VND');
  const [type, setType] = useState<WalletType>('cash');
  const [color, setColor] = useState('#10B981');
  const [isDefault, setIsDefault] = useState(false);
  const [excludeFromTotal, setExcludeFromTotal] = useState(false);
  const [creditLimit, setCreditLimit] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (editingWallet) {
      setName(editingWallet.name);
      setBalance(editingWallet.balance.toString());
      setCurrency(editingWallet.currency || 'VND');
      setType(editingWallet.type);
      setColor(editingWallet.color || '#10B981');
      setIsDefault(editingWallet.is_default);
      setExcludeFromTotal(editingWallet.exclude_from_total);
      setCreditLimit(editingWallet.credit_limit ? editingWallet.credit_limit.toString() : '');
    } else {
      setName('');
      setBalance('0');
      setCurrency('VND');
      setType('cash');
      setColor('#10B981');
      setIsDefault(false);
      setExcludeFromTotal(false);
      setCreditLimit('');
    }
    setError(null);
  }, [editingWallet, isOpen]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Vui lòng nhập tên ví');
      return;
    }

    const numBalance = parseFloat(balance.replace(/,/g, '')) || 0;
    const numCredit = creditLimit ? parseFloat(creditLimit.replace(/,/g, '')) : undefined;

    setIsSubmitting(true);
    setError(null);

    try {
      if (editingWallet) {
        await updateWallet(editingWallet.cloud_id, {
          name: name.trim(),
          balance: numBalance,
          currency,
          type,
          color,
          is_default: isDefault,
          exclude_from_total: excludeFromTotal,
          credit_limit: numCredit,
        });
      } else {
        await addWallet({
          name: name.trim(),
          balance: numBalance,
          currency,
          type,
          icon: 'Wallet',
          color,
          is_default: isDefault,
          exclude_from_total: excludeFromTotal,
          credit_limit: numCredit,
        });
      }
      onClose();
    } catch (err: any) {
      setError(err.message || 'Lỗi khi lưu ví');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={editingWallet ? 'Chỉnh sửa ví / tài khoản' : 'Thêm ví / tài khoản mới'}
      maxWidth="md"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          label="Tên tài khoản / Ví *"
          placeholder="Ví dụ: Techcombank, Tiền mặt, Thẻ tín dụng..."
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
          autoFocus
        />

        <div className="grid grid-cols-2 gap-3">
          <Input
            label="Số dư ban đầu"
            type="number"
            step="any"
            value={balance}
            onChange={(e) => setBalance(e.target.value)}
          />
          <Select label="Loại tiền tệ" value={currency} onChange={(e) => setCurrency(e.target.value)}>
            <option value="VND">VND (₫)</option>
            <option value="USD">USD ($)</option>
            <option value="EUR">EUR (€)</option>
            <option value="JPY">JPY (¥)</option>
          </Select>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <Select label="Phân loại ví" value={type} onChange={(e) => setType(e.target.value as WalletType)}>
            <option value="cash">Tiền mặt</option>
            <option value="bank">Tài khoản Ngân hàng</option>
            <option value="credit">Thẻ tín dụng (Credit Card)</option>
            <option value="ewallet">Ví điện tử (Momo/ZaloPay)</option>
            <option value="savings">Sổ tiết kiệm</option>
          </Select>
          <div>
            <label className="text-xs font-semibold text-slate-600 dark:text-slate-300 block mb-1.5">
              Màu đại diện
            </label>
            <div className="flex items-center gap-2">
              <input
                type="color"
                value={color}
                onChange={(e) => setColor(e.target.value)}
                className="w-8 h-8 rounded-lg border border-slate-200 cursor-pointer p-0"
              />
              <span className="text-xs text-slate-500 font-mono">{color}</span>
            </div>
          </div>
        </div>

        {type === 'credit' && (
          <Input
            label="Hạn mức thẻ tín dụng"
            type="number"
            step="any"
            placeholder="Ví dụ: 50,000,000"
            value={creditLimit}
            onChange={(e) => setCreditLimit(e.target.value)}
          />
        )}

        <div className="space-y-2 pt-1">
          <label className="flex items-center gap-2 text-xs font-medium text-slate-700 dark:text-slate-300 cursor-pointer">
            <input
              type="checkbox"
              checked={isDefault}
              onChange={(e) => setIsDefault(e.target.checked)}
              className="rounded border-slate-300 text-teal-600 focus:ring-teal-500/20"
            />
            <span>Đặt làm ví mặc định khi thêm giao dịch</span>
          </label>
          <label className="flex items-center gap-2 text-xs font-medium text-slate-700 dark:text-slate-300 cursor-pointer">
            <input
              type="checkbox"
              checked={excludeFromTotal}
              onChange={(e) => setExcludeFromTotal(e.target.checked)}
              className="rounded border-slate-300 text-teal-600 focus:ring-teal-500/20"
            />
            <span>Không tính vào Tổng tài sản ròng</span>
          </label>
        </div>

        {error && <p className="text-xs text-rose-500">{error}</p>}

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="outline" className="flex-1" onClick={onClose}>
            Hủy
          </Button>
          <Button type="submit" variant="primary" className="flex-1" isLoading={isSubmitting}>
            {editingWallet ? 'Lưu thay đổi' : 'Tạo ví mới'}
          </Button>
        </div>
      </form>
    </Modal>
  );
};
