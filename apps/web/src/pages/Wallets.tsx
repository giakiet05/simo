import {
  Plus,
  ArrowLeftRight,
  Wallet as WalletIcon,
  CreditCard,
  Building2,
  Banknote,
  PiggyBank,
  Edit2,
  Trash2,
  CheckCircle2,
  ExternalLink,
} from 'lucide-react';
import { useFinance } from '../contexts/FinanceContext';
import { Button, Card } from '../components/ui';
import type { Wallet } from '../types';

interface WalletsPageProps {
  onOpenNewWallet: () => void;
  onOpenTransfer: () => void;
  onEditWallet: (w: Wallet) => void;
  onViewWalletDetail: (w: Wallet) => void;
}

export const WalletsPage: React.FC<WalletsPageProps> = ({
  onOpenNewWallet,
  onOpenTransfer,
  onEditWallet,
  onViewWalletDetail,
}) => {
  const { wallets, deleteWallet } = useFinance();

  const getWalletIcon = (type: string) => {
    switch (type) {
      case 'bank':
        return <Building2 className="w-5 h-5" />;
      case 'credit':
        return <CreditCard className="w-5 h-5" />;
      case 'savings':
        return <PiggyBank className="w-5 h-5" />;
      case 'ewallet':
        return <WalletIcon className="w-5 h-5" />;
      default:
        return <Banknote className="w-5 h-5" />;
    }
  };

  const getWalletTypeName = (type: string) => {
    switch (type) {
      case 'bank':
        return 'Ngân hàng';
      case 'credit':
        return 'Thẻ tín dụng';
      case 'savings':
        return 'Sổ tiết kiệm';
      case 'ewallet':
        return 'Ví điện tử';
      default:
        return 'Tiền mặt';
    }
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Top Bar */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-slate-900 dark:text-slate-100 tracking-tight">
            Tài khoản & Ví thanh toán
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Tổng số: <span className="font-semibold text-slate-700 dark:text-slate-300">{wallets.length}</span> tài khoản
          </p>
        </div>
        <div className="flex items-center gap-2">
          <Button size="sm" variant="secondary" onClick={onOpenTransfer}>
            <ArrowLeftRight className="w-3.5 h-3.5" />
            <span>Chuyển tiền</span>
          </Button>
          <Button size="sm" variant="primary" onClick={onOpenNewWallet}>
            <Plus className="w-3.5 h-3.5" />
            <span>Thêm ví mới</span>
          </Button>
        </div>
      </div>

      {/* Wallets Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {wallets.map((wallet) => {
          return (
            <Card
              key={wallet.cloud_id}
              className="relative flex flex-col justify-between overflow-hidden hover:shadow-md transition-shadow group"
            >
              {/* Color Stripe */}
              <div
                className="absolute top-0 left-0 right-0 h-1.5"
                style={{ backgroundColor: wallet.color || '#10B981' }}
              />

              <div className="pt-2">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div
                      className="w-10 h-10 rounded-xl flex items-center justify-center text-white shrink-0 shadow-xs"
                      style={{ backgroundColor: wallet.color || '#10B981' }}
                    >
                      {getWalletIcon(wallet.type)}
                    </div>
                    <div>
                      <div className="flex items-center gap-1.5">
                        <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
                          {wallet.name}
                        </h3>
                        {wallet.is_default && (
                          <span title="Ví mặc định">
                            <CheckCircle2 className="w-3.5 h-3.5 text-teal-600 dark:text-teal-400" />
                          </span>
                        )}
                      </div>
                      <span className="text-[11px] text-slate-400 font-medium">
                        {getWalletTypeName(wallet.type)}
                      </span>
                    </div>
                  </div>

                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => onEditWallet(wallet)}
                      className="p-1.5 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800 cursor-pointer"
                      title="Sửa ví"
                    >
                      <Edit2 className="w-3.5 h-3.5" />
                    </button>
                    {wallets.length > 1 && (
                      <button
                        onClick={() => {
                          if (confirm(`Bạn có chắc muốn xóa ví "${wallet.name}"?`)) {
                            deleteWallet(wallet.cloud_id);
                          }
                        }}
                        className="p-1.5 text-slate-400 hover:text-rose-500 rounded-lg hover:bg-rose-50 dark:hover:bg-rose-950/30 cursor-pointer"
                        title="Xóa ví"
                      >
                        <Trash2 className="w-3.5 h-3.5" />
                      </button>
                    )}
                  </div>
                </div>

                <div className="mt-4">
                  <span className="text-[11px] text-slate-400 font-medium">Số dư khả dụng</span>
                  <p className="text-xl font-bold text-slate-900 dark:text-slate-100 mt-0.5">
                    {new Intl.NumberFormat('vi-VN').format(wallet.balance)} {wallet.currency || 'VND'}
                  </p>
                </div>

                {wallet.credit_limit ? (
                  <div className="mt-2 text-[11px] text-slate-400">
                    Hạn mức tín dụng: {new Intl.NumberFormat('vi-VN').format(wallet.credit_limit)} ₫
                  </div>
                ) : null}
              </div>

              <div className="pt-4 mt-4 border-t border-slate-100 dark:border-slate-800 flex justify-between items-center text-xs">
                {wallet.exclude_from_total ? (
                  <span className="text-[10px] text-amber-600 dark:text-amber-400">Không tính vào tổng</span>
                ) : (
                  <span className="text-[10px] text-slate-400">Tính vào tổng tài sản</span>
                )}
                <button
                  onClick={() => onViewWalletDetail(wallet)}
                  className="flex items-center gap-1 text-xs font-semibold text-teal-600 dark:text-teal-400 hover:underline cursor-pointer"
                >
                  <span>Xem sao kê</span>
                  <ExternalLink className="w-3 h-3" />
                </button>
              </div>
            </Card>
          );
        })}
      </div>
    </div>
  );
};
