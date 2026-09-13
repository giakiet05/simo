import { useState, useEffect } from 'react';
import { Modal, Input, Button } from './ui';
import { useFinance } from '../contexts/FinanceContext';
import type { Category, CategoryType } from '../types';

interface CategoryModalProps {
  isOpen: boolean;
  onClose: () => void;
  editingCategory?: Category | null;
}

export const CategoryModal: React.FC<CategoryModalProps> = ({
  isOpen,
  onClose,
  editingCategory,
}) => {
  const { addCategory, updateCategory } = useFinance();

  const [name, setName] = useState('');
  const [type, setType] = useState<CategoryType>('expense');
  const [color, setColor] = useState('#F97316');
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (editingCategory) {
      setName(editingCategory.name);
      setType(editingCategory.type);
      setColor(editingCategory.color || '#F97316');
    } else {
      setName('');
      setType('expense');
      setColor('#F97316');
    }
    setError(null);
  }, [editingCategory, isOpen]);

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) {
      setError('Vui lòng nhập tên danh mục');
      return;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      if (editingCategory) {
        await updateCategory(editingCategory.cloud_id, {
          name: name.trim(),
          type,
          color,
        });
      } else {
        await addCategory({
          name: name.trim(),
          type,
          icon: 'Tag',
          color,
        });
      }
      onClose();
    } catch (err: any) {
      setError(err.message || 'Lỗi khi lưu danh mục');
    } finally {
      setIsSubmitting(false);
    }
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={editingCategory ? 'Chỉnh sửa danh mục' : 'Thêm danh mục mới'}
      maxWidth="md"
    >
      <form onSubmit={handleSubmit} className="space-y-4">
        <div className="grid grid-cols-2 gap-2 p-1 bg-slate-100 dark:bg-slate-800 rounded-xl">
          <button
            type="button"
            onClick={() => setType('expense')}
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
            onClick={() => setType('income')}
            className={`py-2 text-xs font-semibold rounded-lg transition-all cursor-pointer ${
              type === 'income'
                ? 'bg-emerald-500 text-white shadow-xs'
                : 'text-slate-600 dark:text-slate-400 hover:text-slate-900'
            }`}
          >
            Thu nhập (Income)
          </button>
        </div>

        <Input
          label="Tên danh mục *"
          placeholder="Ví dụ: Ăn uống, Mua sắm, Du lịch..."
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
          autoFocus
        />

        <div>
          <label className="text-xs font-semibold text-slate-600 dark:text-slate-300 block mb-1.5">
            Màu sắc nhận diện
          </label>
          <div className="flex items-center gap-3">
            <input
              type="color"
              value={color}
              onChange={(e) => setColor(e.target.value)}
              className="w-10 h-10 rounded-xl border border-slate-200 cursor-pointer p-0"
            />
            <span className="text-xs text-slate-500 font-mono">{color}</span>
          </div>
        </div>

        {error && <p className="text-xs text-rose-500">{error}</p>}

        <div className="flex gap-2 pt-2">
          <Button type="button" variant="outline" className="flex-1" onClick={onClose}>
            Hủy
          </Button>
          <Button type="submit" variant="primary" className="flex-1" isLoading={isSubmitting}>
            {editingCategory ? 'Lưu thay đổi' : 'Tạo danh mục'}
          </Button>
        </div>
      </form>
    </Modal>
  );
};
