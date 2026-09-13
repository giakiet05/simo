import {
  Plus,
  Target,
  ArrowDownLeft,
  ArrowUpRight,
  Edit2,
  Trash2,
  Calendar,
} from 'lucide-react';
import { useFinance } from '../contexts/FinanceContext';
import { Button, Card, Badge } from '../components/ui';
import type { SavingGoal } from '../types';

interface SavingGoalsPageProps {
  onOpenNewGoal: () => void;
  onEditGoal: (goal: SavingGoal) => void;
  onOpenDeposit: (goal: SavingGoal) => void;
  onOpenWithdraw: (goal: SavingGoal) => void;
}

export const SavingGoalsPage: React.FC<SavingGoalsPageProps> = ({
  onOpenNewGoal,
  onEditGoal,
  onOpenDeposit,
  onOpenWithdraw,
}) => {
  const { savingGoals, deleteSavingGoal } = useFinance();

  const totalTarget = savingGoals.reduce((sum, g) => sum + Number(g.target_amount), 0);
  const totalAccumulated = savingGoals.reduce((sum, g) => sum + Number(g.current_amount), 0);

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Top Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-slate-900 dark:text-slate-100 tracking-tight">
            Mục tiêu tích lũy
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Kế hoạch hóa và theo dõi tiến độ tiết kiệm cho các dự định tài chính
          </p>
        </div>
        <Button size="sm" variant="primary" onClick={onOpenNewGoal}>
          <Plus className="w-3.5 h-3.5" />
          <span>Thêm mục tiêu mới</span>
        </Button>
      </div>

      {/* Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card className="flex items-center justify-between p-5">
          <div>
            <span className="text-xs text-slate-400 font-medium">Tổng tiền đã tích lũy</span>
            <p className="text-2xl font-black text-teal-600 dark:text-teal-400 mt-1">
              {new Intl.NumberFormat('vi-VN').format(totalAccumulated)} ₫
            </p>
          </div>
          <div className="w-12 h-12 rounded-2xl bg-teal-50 dark:bg-teal-950/40 text-teal-600 dark:text-teal-400 flex items-center justify-center">
            <Target className="w-6 h-6" />
          </div>
        </Card>

        <Card className="flex items-center justify-between p-5">
          <div>
            <span className="text-xs text-slate-400 font-medium">Tổng mục tiêu cần đạt</span>
            <p className="text-2xl font-black text-slate-900 dark:text-slate-100 mt-1">
              {new Intl.NumberFormat('vi-VN').format(totalTarget)} ₫
            </p>
          </div>
          <div className="w-12 h-12 rounded-2xl bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 flex items-center justify-center font-bold text-sm">
            {savingGoals.length} mục
          </div>
        </Card>
      </div>

      {/* Goals Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {savingGoals.length === 0 ? (
          <Card className="col-span-full py-12 text-center text-slate-400 space-y-3">
            <p className="text-sm">Chưa có mục tiêu tiết kiệm nào được tạo</p>
            <Button size="sm" variant="primary" onClick={onOpenNewGoal}>
              Tạo mục tiêu đầu tiên
            </Button>
          </Card>
        ) : (
          savingGoals.map((goal) => {
            const isCompleted = goal.current_amount >= goal.target_amount && goal.target_amount > 0;
            const pct = goal.target_amount > 0
              ? Math.min(100, Math.round((goal.current_amount / goal.target_amount) * 100))
              : 0;
            const remaining = Math.max(0, goal.target_amount - goal.current_amount);

            return (
              <Card
                key={goal.cloud_id}
                className="flex flex-col justify-between overflow-hidden hover:shadow-md transition-shadow relative"
              >
                <div
                  className="absolute top-0 left-0 right-0 h-1.5"
                  style={{ backgroundColor: goal.color || '#10B981' }}
                />

                <div className="pt-2">
                  <div className="flex items-start justify-between">
                    <div>
                      <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
                        {goal.name}
                      </h3>
                      <div className="flex items-center gap-1 text-[11px] text-slate-400 mt-1">
                        <Calendar className="w-3 h-3" />
                        <span>Hạn: {goal.target_date || 'Không giới hạn'}</span>
                      </div>
                    </div>

                    <div className="flex items-center gap-1">
                      <button
                        onClick={() => onEditGoal(goal)}
                        className="p-1 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 cursor-pointer"
                        title="Sửa mục tiêu"
                      >
                        <Edit2 className="w-3.5 h-3.5" />
                      </button>
                      <button
                        onClick={() => {
                          if (confirm(`Bạn có chắc muốn xóa mục tiêu "${goal.name}"?`)) {
                            deleteSavingGoal(goal.cloud_id);
                          }
                        }}
                        className="p-1 text-slate-400 hover:text-rose-500 rounded-lg hover:bg-rose-50 dark:hover:bg-rose-950/30 cursor-pointer"
                        title="Xóa mục tiêu"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    </div>
                  </div>

                  <div className="mt-4 space-y-2">
                    <div className="flex justify-between items-end text-xs">
                      <div>
                        <span className="text-[10px] text-slate-400 uppercase font-semibold">
                          Đã tích lũy
                        </span>
                        <p className="text-lg font-black text-slate-900 dark:text-slate-100">
                          {new Intl.NumberFormat('vi-VN').format(goal.current_amount)} ₫
                        </p>
                      </div>
                      <Badge variant={isCompleted ? 'success' : 'info'}>
                        {isCompleted ? 'Hoàn thành!' : `${pct}%`}
                      </Badge>
                    </div>

                    <div className="h-2.5 bg-slate-100 dark:bg-slate-800 rounded-full overflow-hidden">
                      <div
                        className="h-full rounded-full transition-all duration-500"
                        style={{
                          width: `${pct}%`,
                          backgroundColor: goal.color || '#10B981',
                        }}
                      />
                    </div>

                    <div className="flex justify-between text-[11px] text-slate-400 pt-1">
                      <span>Mục tiêu: {new Intl.NumberFormat('vi-VN').format(goal.target_amount)} ₫</span>
                      <span>Còn thiếu: {new Intl.NumberFormat('vi-VN').format(remaining)} ₫</span>
                    </div>
                  </div>
                </div>

                <div className="pt-3 mt-4 border-t border-slate-100 dark:border-slate-800 flex gap-2">
                  <Button
                    size="sm"
                    variant="outline"
                    className="flex-1 text-xs"
                    onClick={() => onOpenWithdraw(goal)}
                    disabled={goal.current_amount <= 0}
                  >
                    <ArrowUpRight className="w-3.5 h-3.5 text-rose-500" />
                    <span>Rút tiền</span>
                  </Button>
                  <Button
                    size="sm"
                    variant="secondary"
                    className="flex-1 text-xs"
                    onClick={() => onOpenDeposit(goal)}
                  >
                    <ArrowDownLeft className="w-3.5 h-3.5 text-emerald-500" />
                    <span>Nạp tiền</span>
                  </Button>
                </div>
              </Card>
            );
          })
        )}
      </div>
    </div>
  );
};
