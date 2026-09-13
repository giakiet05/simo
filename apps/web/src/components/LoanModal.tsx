import React, { useState, useEffect } from 'react';
import { Modal, Input, Button, Select } from './ui';
import { useFinance } from '../contexts/FinanceContext';
import type { LoanContact, LoanType } from '../types';

interface LoanContactModalProps {
  isOpen: boolean;
  onClose: () => void;
  editingContact?: LoanContact | null;
}

export const LoanContactModal: React.FC<LoanContactModalProps> = ({
  isOpen,
  onClose,
  editingContact,
}) => {
  const { addLoanContact, updateLoanContact } = useFinance();
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [note, setNote] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (editingContact) {
      setName(editingContact.name);
      setPhone(editingContact.phone || '');
      setNote(editingContact.note || '');
    } else {
      setName('');
      setPhone('');
      setNote('');
    }
    setError(null);
  }, [editingContact, isOpen]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Vui lòng nhập tên người vay / cho vay');
      return;
    }
    setIsSubmitting(true);
    setError(null);

    try {
      if (editingContact) {
        await updateLoanContact(editingContact.cloud_id, {
          name: name.trim(),
          phone: phone.trim() || undefined,
          note: note.trim() || undefined,
        });
      } else {
        await addLoanContact({
          name: name.trim(),
          phone: phone.trim() || undefined,
          note: note.trim() || undefined,
        });
      }
      onClose();
    } catch (err: any) {
      setError(err.message || 'Lỗi khi lưu liên hệ sổ nợ');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={editingContact ? 'Chỉnh sửa người nợ' : 'Thêm người nợ mới'}
      maxWidth="md"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          label="Tên liên hệ *"
          placeholder="Ví dụ: Bạn Nam, Anh Hoàng, Chị Mai..."
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
          autoFocus
        />
        <Input
          label="Số điện thoại"
          placeholder="09xx..."
          value={phone}
          onChange={(e) => setPhone(e.target.value)}
        />
        <Input
          label="Ghi chú quan hệ"
          placeholder="Ví dụ: Bạn cùng phòng, đồng nghiệp..."
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />

        {error && <p className="text-xs text-rose-500">{error}</p>}

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="outline" className="flex-1" onClick={onClose}>
            Hủy
          </Button>
          <Button type="submit" variant="primary" className="flex-1" isLoading={isSubmitting}>
            {editingContact ? 'Lưu thay đổi' : 'Tạo liên hệ'}
          </Button>
        </div>
      </form>
    </Modal>
  );
};

interface LoanTransactionModalProps {
  isOpen: boolean;
  onClose: () => void;
  contact: LoanContact | null;
  defaultType?: LoanType;
}

export const LoanTransactionModal: React.FC<LoanTransactionModalProps> = ({
  isOpen,
  onClose,
  contact,
  defaultType = 'lend',
}) => {
  const { wallets, addLoanTransaction } = useFinance();
  const [type, setType] = useState<LoanType>(defaultType);
  const [walletId, setWalletId] = useState('');
  const [amount, setAmount] = useState('');
  const [date, setDate] = useState('');
  const [note, setNote] = useState('');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    setType(defaultType);
    if (wallets.length > 0) {
      const def = wallets.find((w) => w.is_default) || wallets[0];
      setWalletId(def.cloud_id);
    }
    setAmount('');
    const now = new Date();
    now.setMinutes(now.getMinutes() - now.getTimezoneOffset());
    setDate(now.toISOString().substring(0, 16));
    setNote('');
    setError(null);
  }, [isOpen, defaultType, wallets]);

  if (!contact) return null;

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
      await addLoanTransaction({
        contact_id: contact.cloud_id,
        wallet_id: walletId || undefined,
        type,
        amount: numAmount,
        date: new Date(date).toISOString(),
        note: note.trim() || undefined,
      });
      onClose();
    } catch (err: any) {
      setError(err.message || 'Lỗi khi lưu giao dịch nợ');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={`Ghi nhận giao dịch nợ: ${contact.name}`}
      maxWidth="md"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <Select label="Loại giao dịch *" value={type} onChange={(e) => setType(e.target.value as LoanType)}>
          <option value="lend">Cho vay (Tôi đưa tiền cho người này)</option>
          <option value="borrow">Đi vay (Tôi nhận tiền từ người này)</option>
          <option value="repayment_received">Thu nợ (Người này trả lại tiền cho tôi)</option>
          <option value="repayment_paid">Trả nợ (Tôi trả lại tiền cho người này)</option>
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

        <Select
          label="Tài khoản / Ví liên quan"
          value={walletId}
          onChange={(e) => setWalletId(e.target.value)}
        >
          <option value="">-- Không qua ví (Tiền mặt ngoài) --</option>
          {wallets.map((w) => (
            <option key={w.cloud_id} value={w.cloud_id}>
              {w.name} ({new Intl.NumberFormat('vi-VN').format(w.balance)})
            </option>
          ))}
        </Select>

        <Input
          label="Thời gian *"
          type="datetime-local"
          value={date}
          onChange={(e) => setDate(e.target.value)}
          required
        />

        <Input
          label="Ghi chú chi tiết"
          placeholder="Ví dụ: Vay tiền ăn uống, hẹn cuối tuần trả..."
          value={note}
          onChange={(e) => setNote(e.target.value)}
        />

        {error && <p className="text-xs text-rose-500">{error}</p>}

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="outline" className="flex-1" onClick={onClose}>
            Hủy
          </Button>
          <Button type="submit" variant="primary" className="flex-1" isLoading={isSubmitting}>
            Lưu giao dịch
          </Button>
        </div>
      </form>
    </Modal>
  );
};
