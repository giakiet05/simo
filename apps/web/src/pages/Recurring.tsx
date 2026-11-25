import { Plus, Repeat, Edit2, Trash2, Clock } from 'lucide-react';
import { useFinance } from '../contexts/FinanceContext';
import { Button, Card, Badge } from '../components/ui';
import type { RecurringConfig } from '../types';

interface RecurringPageProps {
  onOpenNewRecurring: () => void;
  onEditRecurring: (config: RecurringConfig) => void;
}

const ISO_DAY_LABELS: Record<number, string> = {
  1: 'T2',
  2: 'T3',
  3: 'T4',
  4: 'T5',
  5: 'T6',
  6: 'T7',
  7: 'CN',
};

/**
 * Formats an array of ISO weekdays (1=Mon..7=Sun) into a concise summary string.
 *
 * @param days Sorted ISO weekday list.
 * @returns Human-readable weekday label.
 */
function formatDaysOfWeekSummary(days: number[]): string {
  const sorted = [...days].sort((a, b) => a - b);
  if (sorted.length === 5 && sorted.every((d, idx) => d === idx + 1)) {
    return 'T2 - T6';
  }
  if (sorted.length === 2 && sorted[0] === 6 && sorted[1] === 7) {
    return 'T7 - CN';
  }
  if (sorted.length === 7) {
    return 'Mỗi ngày';
  }
  return sorted.map((d) => ISO_DAY_LABELS[d] || '').filter(Boolean).join(', ');
}

/**
 * Formats a recurring schedule badge label including frequency, interval, and active days.
 *
 * @param cfg Recurring configuration record.
 * @returns Human-readable schedule summary.
 */
function formatScheduleSummary(cfg: RecurringConfig): string {
  const interval = cfg.interval || 1;
  let base: string;
  switch (cfg.frequency) {
    case 'daily':
      base = interval === 1 ? 'Hàng ngày' : `Mỗi ${interval} ngày`;
      break;
    case 'weekly':
      base = interval === 1 ? 'Hàng tuần' : `Mỗi ${interval} tuần`;
      break;
    case 'yearly':
      base = interval === 1 ? 'Hàng năm' : `Mỗi ${interval} năm`;
      break;
    default:
      base = interval === 1 ? 'Hàng tháng' : `Mỗi ${interval} tháng`;
      break;
  }

  const effectiveDays =
    cfg.days_of_week && cfg.days_of_week.length > 0
      ? cfg.days_of_week
      : cfg.frequency === 'weekly' && cfg.day_of_week !== undefined
        ? [cfg.day_of_week % 7 === 0 ? 7 : cfg.day_of_week % 7]
        : null;

  if (cfg.frequency === 'daily' && effectiveDays && effectiveDays.length < 7) {
    return `${base} · ${formatDaysOfWeekSummary(effectiveDays)}`;
  }
  if (cfg.frequency === 'weekly' && effectiveDays && effectiveDays.length > 0) {
    return `${base} · ${formatDaysOfWeekSummary(effectiveDays)}`;
  }
  if (cfg.frequency === 'monthly' && cfg.day_of_month) {
    return `${base} · Ngày ${cfg.day_of_month}`;
  }
  return base;
}

/**
 * Formats an ISO timestamp or date string into dd/MM/yyyy using the browser's local timezone.
 *
 * @param raw Raw timestamp or date string.
 * @returns Formatted date string or N/A.
 */
function formatLocalDate(raw?: string): string {
  if (!raw) return 'N/A';
  const d = new Date(raw);
  if (Number.isNaN(d.getTime())) return raw;
  return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`;
}

export const RecurringPage: React.FC<RecurringPageProps> = ({
  onOpenNewRecurring,
  onEditRecurring,
}) => {
  const { recurringConfigs, categories, wallets, deleteRecurringConfig } = useFinance();

  const catMap = new Map(categories.map((c) => [c.cloud_id, c]));
  const walletMap = new Map(wallets.map((w) => [w.cloud_id, w]));

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Top Bar */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-slate-900 dark:text-slate-100 tracking-tight">
            Giao dịch định kỳ & Tự động hóa
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Quản lý hóa đơn lặp lại, tiền thuê nhà, tiền lương, các gói đăng ký định kỳ
          </p>
        </div>
        <Button size="sm" variant="primary" onClick={onOpenNewRecurring}>
          <Plus className="w-3.5 h-3.5" />
          <span>Tạo lịch định kỳ mới</span>
        </Button>
      </div>

      {/* List */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {recurringConfigs.length === 0 ? (
          <Card className="col-span-full py-12 text-center text-slate-400 space-y-3">
            <p className="text-sm">Chưa có giao dịch định kỳ nào được thiết lập</p>
            <Button size="sm" variant="primary" onClick={onOpenNewRecurring}>
              Tạo lịch đầu tiên
            </Button>
          </Card>
        ) : (
          recurringConfigs.map((cfg) => {
            const cat = catMap.get(cfg.category_id || '');
            const wal = walletMap.get(cfg.wallet_id || '');
            const isIncome = cfg.type === 'income';
            const isPaused = cfg.is_active === false;

            return (
              <Card
                key={cfg.cloud_id}
                className={`flex flex-col justify-between overflow-hidden hover:shadow-md transition-shadow ${
                  isPaused ? 'opacity-65' : ''
                }`}
              >
                <div>
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-xl bg-teal-50 dark:bg-teal-950/40 text-teal-600 dark:text-teal-400 flex items-center justify-center shrink-0">
                        <Repeat className="w-5 h-5" />
                      </div>
                      <div>
                        <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
                          {cfg.name || cfg.note || cat?.name || 'Giao dịch định kỳ'}
                        </h3>
                        <div className="flex flex-wrap items-center gap-1.5 mt-1">
                          <Badge variant="default">{formatScheduleSummary(cfg)}</Badge>
                          {isPaused && <Badge variant="warning">Tạm dừng</Badge>}
                        </div>
                      </div>
                    </div>

                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => onEditRecurring(cfg)}
                        className="p-1.5 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800"
                        title="Sửa"
                      >
                        <Edit2 className="w-3.5 h-3.5" />
                      </button>
                      <button
                        onClick={() => {
                          if (confirm('Bạn có chắc muốn xóa lịch định kỳ này?')) {
                            deleteRecurringConfig(cfg.cloud_id);
                          }
                        }}
                        className="p-1.5 text-slate-400 hover:text-rose-500 rounded-lg hover:bg-rose-50 dark:hover:bg-rose-950/30"
                        title="Xóa"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>

                  <div className="mt-4">
                    <span className="text-[11px] text-slate-400 font-medium">Số tiền định kỳ</span>
                    <p
                      className={`text-xl font-bold mt-0.5 ${
                        isIncome
                          ? 'text-emerald-600 dark:text-emerald-400'
                          : 'text-rose-600 dark:text-rose-400'
                      }`}
                    >
                      {isIncome ? '+' : '-'} {new Intl.NumberFormat('vi-VN').format(cfg.amount)} ₫
                    </p>
                  </div>

                  <div className="mt-3 space-y-1 text-[11px] text-slate-500">
                    <div className="flex justify-between">
                      <span>Danh mục:</span>
                      <span className="font-semibold text-slate-700 dark:text-slate-300">
                        {cat?.name || 'Chưa gán'}
                      </span>
                    </div>
                    <div className="flex justify-between">
                      <span>Tài khoản ví:</span>
                      <span className="font-semibold text-slate-700 dark:text-slate-300">
                        {wal?.name || 'Chưa gán'}
                      </span>
                    </div>
                  </div>
                </div>

                <div className="pt-3 mt-4 border-t border-slate-100 dark:border-slate-800 flex items-center justify-between text-[11px] text-slate-400">
                  <div className="flex items-center gap-1">
                    <Clock className="w-3.5 h-3.5 text-teal-600" />
                    <span>Đến hạn: {formatLocalDate(cfg.next_run || cfg.next_run_date)}</span>
                  </div>
                </div>
              </Card>
            );
          })
        )}
      </div>
    </div>
  );
};
