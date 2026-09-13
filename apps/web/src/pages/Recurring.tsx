import { Plus, Repeat, Edit2, Trash2, Clock } from 'lucide-react';
import { useFinance } from '../contexts/FinanceContext';
import { Button, Card, Badge } from '../components/ui';
import type { RecurringConfig } from '../types';

interface RecurringPageProps {
  onOpenNewRecurring: () => void;
  onEditRecurring: (config: RecurringConfig) => void;
}

export const RecurringPage: React.FC<RecurringPageProps> = ({
  onOpenNewRecurring,
  onEditRecurring,
}) => {
  const { recurringConfigs, categories, wallets, deleteRecurringConfig } = useFinance();

  const catMap = new Map(categories.map((c) => [c.cloud_id, c]));
  const walletMap = new Map(wallets.map((w) => [w.cloud_id, w]));

  const getFrequencyName = (freq: string) => {
    switch (freq) {
      case 'daily':
        return 'Hàng ngày';
      case 'weekly':
        return 'Hàng tuần';
      case 'yearly':
        return 'Hàng năm';
      default:
        return 'Hàng tháng';
    }
  };

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

            return (
              <Card
                key={cfg.cloud_id}
                className="flex flex-col justify-between overflow-hidden hover:shadow-md transition-shadow"
              >
                <div>
                  <div className="flex items-start justify-between">
                    <div className="flex items-center gap-3">
                      <div className="w-9 h-9 rounded-xl bg-teal-50 dark:bg-teal-950/40 text-teal-600 dark:text-teal-400 flex items-center justify-center shrink-0">
                        <Repeat className="w-5 h-5" />
                      </div>
                      <div>
                        <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
                          {cfg.note || cat?.name || 'Giao dịch định kỳ'}
                        </h3>
                        <Badge variant="default" className="mt-1">
                          {getFrequencyName(cfg.frequency)}
                        </Badge>
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
                    <p className="text-xl font-bold text-slate-900 dark:text-slate-100 mt-0.5">
                      {new Intl.NumberFormat('vi-VN').format(cfg.amount)} ₫
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
                    <span>Đến hạn: {cfg.next_run_date || 'N/A'}</span>
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
