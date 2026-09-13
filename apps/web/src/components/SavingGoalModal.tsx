import React, { useState, useEffect } from 'react';
import { Modal, Input, Button } from './ui';
import { useFinance } from '../contexts/FinanceContext';
import type { SavingGoal } from '../types';

interface SavingGoalModalProps {
  isOpen: boolean;
  onClose: () => void;
  editingGoal?: SavingGoal | null;
}

export const SavingGoalModal: React.FC<SavingGoalModalProps> = ({
  isOpen,
  onClose,
  editingGoal,
}) => {
  const { addSavingGoal, updateSavingGoal } = useFinance();

  const [name, setName] = useState('');
  const [targetAmount, setTargetAmount] = useState('');
  const [currentAmount, setCurrentAmount] = useState('0');
  const [targetDate, setTargetDate] = useState('');
  const [color, setColor] = useState('#10B981');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (editingGoal) {
      setName(editingGoal.name);
      setTargetAmount(editingGoal.target_amount.toString());
      setCurrentAmount(editingGoal.current_amount.toString());
      setTargetDate(editingGoal.target_date || '');
      setColor(editingGoal.color || '#10B981');
    } else {
      setName('');
      setTargetAmount('');
      setCurrentAmount('0');
      const d = new Date();
      d.setMonth(d.getMonth() + 6);
      setTargetDate(d.toISOString().split('T')[0]);
      setColor('#10B981');
    }
    setError(null);
  }, [editingGoal, isOpen]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Vui lòng nhập tên mục tiêu');
      return;
    }
    const numTarget = parseFloat(targetAmount.replace(/,/g, ''));
    if (isNaN(numTarget) || numTarget <= 0) {
      setError('Vui lòng nhập số tiền mục tiêu hợp lệ');
      return;
    }
    const numCurrent = parseFloat(currentAmount.replace(/,/g, '')) || 0;

    setIsSubmitting(true);
    setError(null);

    try {
      if (editingGoal) {
        await updateSavingGoal(editingGoal.cloud_id, {
          name: name.trim(),
          target_amount: numTarget,
          current_amount: numCurrent,
          target_date: targetDate,
          color,
        });
      } else {
        await addSavingGoal({
          name: name.trim(),
          target_amount: numTarget,
          current_amount: numCurrent,
          target_date: targetDate,
          icon: 'Target',
          color,
        });
      }
      onClose();
    } catch (err: any) {
      setError(err.message || 'Lỗi khi lưu mục tiêu tiết kiệm');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={editingGoal ? 'Chỉnh sửa mục tiêu tích lũy' : 'Thêm mục tiêu tích lũy mới'}
      maxWidth="md"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <Input
          label="Tên mục tiêu tích lũy *"
          placeholder="Ví dụ: Mua Macbook M4, Quỹ khẩn cấp, Đi du lịch Nhật Bản..."
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
          autoFocus
        />

        <div className="grid grid-cols-2 gap-3">
          <Input
            label="Số tiền cần đạt *"
            type="number"
            step="any"
            placeholder="0"
            value={targetAmount}
            onChange={(e) => setTargetAmount(e.target.value)}
            required
          />
          <Input
            label="Đã tích lũy ban đầu"
            type="number"
            step="any"
            placeholder="0"
            value={currentAmount}
            onChange={(e) => setCurrentAmount(e.target.value)}
          />
        </div>

        <div className="grid grid-cols-2 gap-3">
          <Input
            label="Ngày dự kiến hoàn thành"
            type="date"
            value={targetDate}
            onChange={(e) => setTargetDate(e.target.value)}
            required
          />
          <div>
            <label className="text-xs font-semibold text-slate-600 dark:text-slate-300 block mb-1.5">
              Màu đại diện
            </label>
            <div className="flex items-center gap-2">
              <input
                type="color"
                value={color}
                onChange={(e) => setColor(e.target.value)}
                className="w-9 h-9 rounded-xl border border-slate-200 cursor-pointer p-0"
              />
              <span className="text-xs text-slate-500 font-mono">{color}</span>
            </div>
          </div>
        </div>

        {error && <p className="text-xs text-rose-500">{error}</p>}

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="outline" className="flex-1" onClick={onClose}>
            Hủy
          </Button>
          <Button type="submit" variant="primary" className="flex-1" isLoading={isSubmitting}>
            {editingGoal ? 'Lưu thay đổi' : 'Tạo mục tiêu'}
          </Button>
        </div>
      </form>
    </Modal>
  );
};
