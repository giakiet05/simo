import React, { useState, useEffect } from 'react';
import { Modal, Input, Button, Select } from './ui';
import { useFinance } from '../contexts/FinanceContext';
import type { RecurringConfig, RecurringFrequency, TransactionType } from '../types';

interface RecurringModalProps {
  isOpen: boolean;
  onClose: () => void;
  editingConfig?: RecurringConfig | null;
}

const ALL_ISO_DAYS = [1, 2, 3, 4, 5, 6, 7];
const WEEKDAYS_ISO = [1, 2, 3, 4, 5];
const WEEKENDS_ISO = [6, 7];
const DAY_OPTIONS: { iso: number; label: string }[] = [
  { iso: 1, label: 'T2' },
  { iso: 2, label: 'T3' },
  { iso: 3, label: 'T4' },
  { iso: 4, label: 'T5' },
  { iso: 5, label: 'T6' },
  { iso: 6, label: 'T7' },
  { iso: 7, label: 'CN' },
];

/**
 * Formats a Date or ISO timestamp into a local YYYY-MM-DD date string for HTML date inputs.
 *
 * @param raw Optional ISO timestamp or YYYY-MM-DD string.
 * @returns Local YYYY-MM-DD string.
 */
function toLocalDateInput(raw?: string): string {
  const date = raw ? new Date(raw) : new Date();
  if (Number.isNaN(date.getTime())) {
    const now = new Date();
    return `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
  }
  return `${date.getFullYear()}-${String(date.getMonth() + 1).padStart(2, '0')}-${String(date.getDate()).padStart(2, '0')}`;
}

/**
 * Converts a YYYY-MM-DD local date string into an ISO timestamp at local midnight.
 *
 * @param dateInput YYYY-MM-DD string.
 * @returns ISO timestamp string.
 */
function localDateInputToIso(dateInput: string): string {
  const [y, m, d] = dateInput.split('-').map(Number);
  if (!y || !m || !d) return new Date().toISOString();
  return new Date(y, m - 1, d, 0, 0, 0, 0).toISOString();
}

/**
 * Converts a JS Date.getDay() value (0=Sun..6=Sat) to ISO weekday (1=Mon..7=Sun).
 *
 * @param jsDay Legacy 0-indexed weekday.
 * @returns ISO weekday in range 1..7.
 */
function legacyDayToIso(jsDay: number): number {
  const mod = jsDay % 7;
  return mod === 0 ? 7 : mod;
}

/**
 * Modal dialog for creating or editing a recurring transaction schedule, including weekday filters.
 */
export const RecurringModal: React.FC<RecurringModalProps> = ({
  isOpen,
  onClose,
  editingConfig,
}) => {
  const { categories, wallets, addRecurringConfig, updateRecurringConfig } = useFinance();

  const [name, setName] = useState('');
  const [type, setType] = useState<TransactionType>('expense');
  const [frequency, setFrequency] = useState<RecurringFrequency>('monthly');
  const [interval, setInterval] = useState('1');
  const [selectedDays, setSelectedDays] = useState<number[]>(ALL_ISO_DAYS);
  const [dayOfMonth, setDayOfMonth] = useState<number>(new Date().getDate());
  const [amount, setAmount] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [walletId, setWalletId] = useState('');
  const [nextRunDate, setNextRunDate] = useState('');
  const [isActive, setIsActive] = useState(true);
  const [isSubmitting, setIsSubmitting] = useState(false);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    if (!isOpen) return;

    if (editingConfig) {
      setName(editingConfig.name || editingConfig.note || '');
      setType(editingConfig.type || 'expense');
      setFrequency(editingConfig.frequency);
      setInterval(String(editingConfig.interval || 1));
      if (editingConfig.days_of_week && editingConfig.days_of_week.length > 0) {
        setSelectedDays([...editingConfig.days_of_week].sort((a, b) => a - b));
      } else if (editingConfig.frequency === 'weekly' && editingConfig.day_of_week !== undefined) {
        setSelectedDays([legacyDayToIso(editingConfig.day_of_week)]);
      } else if (editingConfig.frequency === 'daily') {
        setSelectedDays(ALL_ISO_DAYS);
      } else {
        setSelectedDays([legacyDayToIso(new Date().getDay())]);
      }
      setDayOfMonth(editingConfig.day_of_month || new Date().getDate());
      setAmount(editingConfig.amount.toString());
      setCategoryId(editingConfig.category_id || '');
      setWalletId(editingConfig.wallet_id || '');
      setNextRunDate(toLocalDateInput(editingConfig.next_run || editingConfig.next_run_date));
      setIsActive(editingConfig.is_active !== false);
    } else {
      const today = new Date();
      setName('');
      setType('expense');
      setFrequency('monthly');
      setInterval('1');
      setSelectedDays(ALL_ISO_DAYS);
      setDayOfMonth(today.getDate());
      setAmount('');
      const firstCat = categories.find((c) => c.type === 'expense') || categories[0];
      setCategoryId(firstCat ? firstCat.cloud_id : '');
      const defWallet = wallets.find((w) => w.is_default) || wallets[0];
      setWalletId(defWallet ? defWallet.cloud_id : '');
      setNextRunDate(toLocalDateInput());
      setIsActive(true);
    }
    setError(null);
  }, [editingConfig, isOpen, categories, wallets]);

  const filteredCategories = categories.filter((c) => c.type === type);

  const toggleDay = (isoDay: number) => {
    setSelectedDays((prev) => {
      if (prev.includes(isoDay)) {
        if (prev.length <= 1) return prev;
        return prev.filter((d) => d !== isoDay);
      }
      return [...prev, isoDay].sort((a, b) => a - b);
    });
  };

  const matchesPreset = (preset: number[]) =>
    selectedDays.length === preset.length && preset.every((d) => selectedDays.includes(d));

  const handleFrequencyChange = (nextFreq: RecurringFrequency) => {
    setFrequency(nextFreq);
    if (nextFreq === 'daily' && selectedDays.length === 0) {
      setSelectedDays(ALL_ISO_DAYS);
    } else if (nextFreq === 'weekly' && (selectedDays.length === 0 || selectedDays.length === 7)) {
      setSelectedDays([legacyDayToIso(new Date().getDay())]);
    }
  };

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();
    const trimmedName = name.trim();
    if (!trimmedName) {
      setError('Vui lòng nhập tên giao dịch định kỳ');
      return;
    }

    const numAmount = parseFloat(amount.replace(/,/g, ''));
    if (isNaN(numAmount) || numAmount <= 0) {
      setError('Vui lòng nhập số tiền hợp lệ');
      return;
    }

    const numInterval = Math.max(1, parseInt(interval, 10) || 1);
    const sortedDays = [...selectedDays].sort((a, b) => a - b);
    const nextRunIso = localDateInputToIso(nextRunDate);

    let daysOfWeekPayload: number[] | undefined;
    let dayOfWeekPayload: number | undefined;
    let dayOfMonthPayload: number | undefined;

    if (frequency === 'daily') {
      daysOfWeekPayload = sortedDays.length === 7 ? undefined : sortedDays;
    } else if (frequency === 'weekly') {
      daysOfWeekPayload = sortedDays;
      dayOfWeekPayload = sortedDays[0] % 7;
    } else if (frequency === 'monthly') {
      dayOfMonthPayload = dayOfMonth;
    }

    setIsSubmitting(true);
    setError(null);

    try {
      const payload = {
        name: trimmedName,
        note: trimmedName,
        type,
        frequency,
        interval: numInterval,
        day_of_week: dayOfWeekPayload,
        days_of_week: daysOfWeekPayload,
        day_of_month: dayOfMonthPayload,
        amount: numAmount,
        category_id: categoryId || undefined,
        wallet_id: walletId || undefined,
        next_run: nextRunIso,
        next_run_date: nextRunIso,
        is_active: isActive,
      };

      if (editingConfig) {
        await updateRecurringConfig(editingConfig.cloud_id, payload);
      } else {
        await addRecurringConfig(payload);
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
        {/* Type selector */}
        <div className="grid grid-cols-2 gap-2">
          <button
            type="button"
            onClick={() => setType('expense')}
            className={`py-2 px-3 rounded-lg text-xs font-semibold border transition-colors ${
              type === 'expense'
                ? 'bg-rose-50 border-rose-500 text-rose-600 dark:bg-rose-950/40 dark:text-rose-400'
                : 'border-slate-200 dark:border-slate-700 text-slate-500'
            }`}
          >
            Chi tiêu (Expense)
          </button>
          <button
            type="button"
            onClick={() => setType('income')}
            className={`py-2 px-3 rounded-lg text-xs font-semibold border transition-colors ${
              type === 'income'
                ? 'bg-emerald-50 border-emerald-500 text-emerald-600 dark:bg-emerald-950/40 dark:text-emerald-400'
                : 'border-slate-200 dark:border-slate-700 text-slate-500'
            }`}
          >
            Thu nhập (Income)
          </button>
        </div>

        <Input
          label="Tên giao dịch định kỳ *"
          placeholder="Ví dụ: Ăn trưa công ty, Tiền thuê nhà, Netflix..."
          value={name}
          onChange={(e) => setName(e.target.value)}
          required
          autoFocus
        />

        <div className="grid grid-cols-2 gap-3">
          <Input
            label="Số tiền *"
            type="number"
            step="any"
            placeholder="0"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            required
          />

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

        <Select
          label="Danh mục"
          value={categoryId}
          onChange={(e) => setCategoryId(e.target.value)}
        >
          <option value="">-- Chọn danh mục --</option>
          {filteredCategories.map((c) => (
            <option key={c.cloud_id} value={c.cloud_id}>
              {c.name}
            </option>
          ))}
        </Select>

        <div className="grid grid-cols-2 gap-3">
          <Select
            label="Tần suất lặp lại *"
            value={frequency}
            onChange={(e) => handleFrequencyChange(e.target.value as RecurringFrequency)}
          >
            <option value="daily">Hàng ngày (Daily)</option>
            <option value="weekly">Hàng tuần (Weekly)</option>
            <option value="monthly">Hàng tháng (Monthly)</option>
            <option value="yearly">Hàng năm (Yearly)</option>
          </Select>

          <Input
            label="Khoảng lặp (Interval)"
            type="number"
            min="1"
            value={interval}
            onChange={(e) => setInterval(e.target.value)}
            required
          />
        </div>

        {/* Multi-select weekday filter for daily and weekly recurrences */}
        {(frequency === 'daily' || frequency === 'weekly') && (
          <div className="space-y-2">
            <div className="flex items-center justify-between">
              <label className="text-xs font-medium text-slate-700 dark:text-slate-300">
                Áp dụng vào các ngày
              </label>
              <div className="flex gap-1.5">
                <button
                  type="button"
                  onClick={() => setSelectedDays(ALL_ISO_DAYS)}
                  className={`px-2 py-0.5 text-[11px] rounded-md border ${
                    matchesPreset(ALL_ISO_DAYS)
                      ? 'bg-teal-600 text-white border-teal-600'
                      : 'border-slate-200 dark:border-slate-700 text-slate-500'
                  }`}
                >
                  Mỗi ngày
                </button>
                <button
                  type="button"
                  onClick={() => setSelectedDays(WEEKDAYS_ISO)}
                  className={`px-2 py-0.5 text-[11px] rounded-md border ${
                    matchesPreset(WEEKDAYS_ISO)
                      ? 'bg-teal-600 text-white border-teal-600'
                      : 'border-slate-200 dark:border-slate-700 text-slate-500'
                  }`}
                >
                  T2 - T6
                </button>
                <button
                  type="button"
                  onClick={() => setSelectedDays(WEEKENDS_ISO)}
                  className={`px-2 py-0.5 text-[11px] rounded-md border ${
                    matchesPreset(WEEKENDS_ISO)
                      ? 'bg-teal-600 text-white border-teal-600'
                      : 'border-slate-200 dark:border-slate-700 text-slate-500'
                  }`}
                >
                  T7 - CN
                </button>
              </div>
            </div>
            <div className="grid grid-cols-7 gap-1.5">
              {DAY_OPTIONS.map((d) => {
                const active = selectedDays.includes(d.iso);
                return (
                  <button
                    key={d.iso}
                    type="button"
                    onClick={() => toggleDay(d.iso)}
                    className={`h-9 rounded-lg text-xs font-semibold border transition-colors ${
                      active
                        ? 'bg-teal-600 border-teal-600 text-white'
                        : 'bg-slate-50 dark:bg-slate-800/60 border-slate-200 dark:border-slate-700 text-slate-600 dark:text-slate-300'
                    }`}
                  >
                    {d.label}
                  </button>
                );
              })}
            </div>
          </div>
        )}

        {frequency === 'monthly' && (
          <Select
            label="Ngày trong tháng"
            value={String(dayOfMonth)}
            onChange={(e) => setDayOfMonth(Number(e.target.value))}
          >
            {Array.from({ length: 31 }, (_, i) => i + 1).map((d) => (
              <option key={d} value={d}>
                Ngày {d}
              </option>
            ))}
          </Select>
        )}

        <Input
          label="Ngày thực thi tiếp theo *"
          type="date"
          value={nextRunDate}
          onChange={(e) => setNextRunDate(e.target.value)}
          required
        />

        {editingConfig && (
          <label className="flex items-center gap-2 text-xs text-slate-700 dark:text-slate-300 cursor-pointer">
            <input
              type="checkbox"
              checked={isActive}
              onChange={(e) => setIsActive(e.target.checked)}
              className="rounded border-slate-300 text-teal-600 focus:ring-teal-500"
            />
            <span>Kích hoạt tự động tạo giao dịch khi tới hạn</span>
          </label>
        )}

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
