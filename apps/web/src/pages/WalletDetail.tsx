import { ArrowLeft, ArrowUpRight, ArrowDownLeft } from 'lucide-react';
import { useFinance } from '../contexts/FinanceContext';
import { Button, Card } from '../components/ui';
import type { Wallet } from '../types';

interface WalletDetailProps {
  wallet: Wallet;
  onBack: () => void;
  onOpenNewTransaction: () => void;
}

export const WalletDetailPage: React.FC<WalletDetailProps> = ({
  wallet,
  onBack,
  onOpenNewTransaction,
}) => {
  const { transactions, categories } = useFinance();

  const catMap = new Map(categories.map((c) => [c.cloud_id, c]));

  const walletTransactions = transactions.filter((t) => t.wallet_id === wallet.cloud_id);

  const totalIn = walletTransactions
    .filter((t) => t.type === 'income')
    .reduce((sum, t) => sum + Number(t.amount), 0);

  const totalOut = walletTransactions
    .filter((t) => t.type === 'expense')
    .reduce((sum, t) => sum + Number(t.amount), 0);

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Header */}
      <div className="flex items-center justify-between gap-4">
        <div className="flex items-center gap-3">
          <Button size="sm" variant="ghost" onClick={onBack}>
            <ArrowLeft className="w-4 h-4 mr-1" />
            <span>Quay lại</span>
          </Button>
          <div>
            <h1 className="text-xl font-bold text-slate-900 dark:text-slate-100 tracking-tight">
              {wallet.name}
            </h1>
            <p className="text-xs text-slate-500">Sao kê lịch sử giao dịch chi tiết</p>
          </div>
        </div>

        <Button size="sm" variant="primary" onClick={onOpenNewTransaction}>
          Thêm giao dịch
        </Button>
      </div>

      {/* Stats row */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
        <Card>
          <span className="text-xs text-slate-400 font-medium">Số dư hiện tại</span>
          <p className="text-2xl font-black text-slate-900 dark:text-slate-100 mt-1">
            {new Intl.NumberFormat('vi-VN').format(wallet.balance)} {wallet.currency || 'VND'}
          </p>
        </Card>
        <Card>
          <div className="flex items-center gap-1.5 text-xs text-emerald-600 font-medium">
            <ArrowDownLeft className="w-4 h-4" />
            <span>Tổng tiền vào</span>
          </div>
          <p className="text-2xl font-bold text-emerald-600 dark:text-emerald-400 mt-1">
            +{new Intl.NumberFormat('vi-VN').format(totalIn)} ₫
          </p>
        </Card>
        <Card>
          <div className="flex items-center gap-1.5 text-xs text-rose-600 font-medium">
            <ArrowUpRight className="w-4 h-4" />
            <span>Tổng tiền ra</span>
          </div>
          <p className="text-2xl font-bold text-rose-600 dark:text-rose-400 mt-1">
            -{new Intl.NumberFormat('vi-VN').format(totalOut)} ₫
          </p>
        </Card>
      </div>

      {/* Transaction History for this wallet */}
      <Card className="p-0 overflow-hidden">
        <div className="p-4 border-b border-slate-100 dark:border-slate-800">
          <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
            Lịch sử giao dịch ({walletTransactions.length})
          </h3>
        </div>

        <div className="divide-y divide-slate-100 dark:divide-slate-800">
          {walletTransactions.length === 0 ? (
            <p className="text-xs text-slate-400 py-10 text-center">Chưa có giao dịch nào qua ví này</p>
          ) : (
            walletTransactions.map((tx) => {
              const cat = catMap.get(tx.category_id || '');
              return (
                <div key={tx.cloud_id} className="flex items-center justify-between p-4 hover:bg-slate-50 dark:hover:bg-slate-800/40">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-9 h-9 rounded-xl flex items-center justify-center text-xs font-bold text-white shrink-0"
                      style={{ backgroundColor: cat?.color || '#94A3B8' }}
                    >
                      {(cat?.name || 'K').charAt(0).toUpperCase()}
                    </div>
                    <div>
                      <p className="text-xs font-semibold text-slate-900 dark:text-slate-100">
                        {tx.note || cat?.name || 'Giao dịch'}
                      </p>
                      <p className="text-[11px] text-slate-400">
                        {tx.date ? new Date(tx.date).toLocaleString('vi-VN') : ''}
                      </p>
                    </div>
                  </div>
                  <span
                    className={`text-sm font-bold ${
                      tx.type === 'income' ? 'text-emerald-600 dark:text-emerald-400' : 'text-rose-600 dark:text-rose-400'
                    }`}
                  >
                    {tx.type === 'income' ? '+' : '-'}
                    {new Intl.NumberFormat('vi-VN').format(tx.amount)} ₫
                  </span>
                </div>
              );
            })
          )}
        </div>
      </Card>
    </div>
  );
};
