import { useState } from 'react';
import {
  ArrowUpRight,
  ArrowDownLeft,
  UserPlus,
  Trash2,
  Edit2,
} from 'lucide-react';
import { useFinance } from '../contexts/FinanceContext';
import { Button, Card, Badge } from '../components/ui';
import type { LoanContact, LoanType } from '../types';

interface LoansPageProps {
  onOpenNewContact: () => void;
  onOpenLoanTransaction: (contact: LoanContact, defaultType?: LoanType) => void;
  onEditContact: (contact: LoanContact) => void;
}

export const LoansPage: React.FC<LoansPageProps> = ({
  onOpenNewContact,
  onOpenLoanTransaction,
  onEditContact,
}) => {
  const { loanContacts, loanTransactions, deleteLoanContact, deleteLoanTransaction } = useFinance();

  const [selectedContactId, setSelectedContactId] = useState<string | null>(
    loanContacts.length > 0 ? loanContacts[0].cloud_id : null
  );

  // Calculate debt per contact
  const contactStats = loanContacts.map((contact) => {
    const txs = loanTransactions.filter((t) => t.contact_id === contact.cloud_id);
    let net = 0; // > 0: they owe me (receivable), < 0: I owe them (payable)
    txs.forEach((t) => {
      if (t.type === 'lend') net += Number(t.amount);
      if (t.type === 'borrow') net -= Number(t.amount);
      if (t.type === 'repayment_received') net -= Number(t.amount);
      if (t.type === 'repayment_paid') net += Number(t.amount);
    });
    return {
      contact,
      netBalance: net,
      txCount: txs.length,
      isSettled: net === 0 && txs.length > 0,
    };
  });

  const totalReceivable = contactStats
    .filter((s) => s.netBalance > 0)
    .reduce((sum, s) => sum + s.netBalance, 0);

  const totalPayable = contactStats
    .filter((s) => s.netBalance < 0)
    .reduce((sum, s) => sum + Math.abs(s.netBalance), 0);

  const selectedContactData = contactStats.find((s) => s.contact.cloud_id === selectedContactId);
  const selectedContactTxs = loanTransactions
    .filter((t) => t.contact_id === selectedContactId)
    .sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Top Header */}
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-bold text-slate-900 dark:text-slate-100 tracking-tight">
            Sổ nợ (Vay & Cho vay)
          </h1>
          <p className="text-xs text-slate-500 dark:text-slate-400">
            Quản lý công nợ cá nhân, người vay, người nợ và lịch sử hoàn trả
          </p>
        </div>
        <Button size="sm" variant="primary" onClick={onOpenNewContact}>
          <UserPlus className="w-3.5 h-3.5" />
          <span>Thêm người nợ / chủ nợ</span>
        </Button>
      </div>

      {/* Overview Cards */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <Card className="flex items-center justify-between p-5">
          <div>
            <span className="text-xs text-slate-400 font-medium">Người khác nợ tôi (Cần thu)</span>
            <p className="text-2xl font-black text-emerald-600 dark:text-emerald-400 mt-1">
              +{new Intl.NumberFormat('vi-VN').format(totalReceivable)} ₫
            </p>
          </div>
          <div className="w-12 h-12 rounded-2xl bg-emerald-50 dark:bg-emerald-950/40 text-emerald-600 dark:text-emerald-400 flex items-center justify-center">
            <ArrowDownLeft className="w-6 h-6" />
          </div>
        </Card>

        <Card className="flex items-center justify-between p-5">
          <div>
            <span className="text-xs text-slate-400 font-medium">Tôi nợ người khác (Cần trả)</span>
            <p className="text-2xl font-black text-rose-600 dark:text-rose-400 mt-1">
              -{new Intl.NumberFormat('vi-VN').format(totalPayable)} ₫
            </p>
          </div>
          <div className="w-12 h-12 rounded-2xl bg-rose-50 dark:bg-rose-950/40 text-rose-600 dark:text-rose-400 flex items-center justify-center">
            <ArrowUpRight className="w-6 h-6" />
          </div>
        </Card>
      </div>

      {/* Main Split View: Contacts list vs Transaction History */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Contact List */}
        <Card className="p-0 overflow-hidden lg:col-span-1">
          <div className="p-4 border-b border-slate-100 dark:border-slate-800">
            <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
              Danh bạ công nợ ({loanContacts.length})
            </h3>
          </div>

          <div className="divide-y divide-slate-100 dark:divide-slate-800 max-h-[500px] overflow-y-auto">
            {contactStats.length === 0 ? (
              <p className="text-xs text-slate-400 py-10 text-center">Chưa có liên hệ nào</p>
            ) : (
              contactStats.map((item) => {
                const isSelected = item.contact.cloud_id === selectedContactId;
                return (
                  <div
                    key={item.contact.cloud_id}
                    onClick={() => setSelectedContactId(item.contact.cloud_id)}
                    className={`flex items-center justify-between p-4 cursor-pointer transition-colors ${
                      isSelected
                        ? 'bg-teal-50 dark:bg-teal-950/40 border-l-4 border-teal-600'
                        : 'hover:bg-slate-50 dark:hover:bg-slate-800/40'
                    }`}
                  >
                    <div>
                      <h4 className="text-xs font-bold text-slate-900 dark:text-slate-100">
                        {item.contact.name}
                      </h4>
                      <span className="text-[11px] text-slate-400">
                        {item.contact.phone || item.contact.note || 'Không có ghi chú'}
                      </span>
                    </div>

                    <div className="text-right">
                      <p
                        className={`text-xs font-bold ${
                          item.netBalance > 0
                            ? 'text-emerald-600 dark:text-emerald-400'
                            : item.netBalance < 0
                            ? 'text-rose-600 dark:text-rose-400'
                            : 'text-slate-400'
                        }`}
                      >
                        {item.netBalance === 0
                          ? '0 ₫ (Tất toán)'
                          : item.netBalance > 0
                          ? `+${new Intl.NumberFormat('vi-VN').format(item.netBalance)} ₫`
                          : `-${new Intl.NumberFormat('vi-VN').format(Math.abs(item.netBalance))} ₫`}
                      </p>
                    </div>
                  </div>
                );
              })
            )}
          </div>
        </Card>

        {/* Selected Contact Detail */}
        <Card className="p-0 overflow-hidden lg:col-span-2">
          {selectedContactData ? (
            <div>
              {/* Header */}
              <div className="p-4 border-b border-slate-100 dark:border-slate-800 flex flex-wrap items-center justify-between gap-4">
                <div>
                  <div className="flex items-center gap-2">
                    <h3 className="text-base font-bold text-slate-900 dark:text-slate-100">
                      {selectedContactData.contact.name}
                    </h3>
                    {selectedContactData.isSettled && (
                      <Badge variant="success">Đã tất toán</Badge>
                    )}
                  </div>
                  <p className="text-xs text-slate-400 mt-0.5">
                    Số dư hiện tại:{' '}
                    <span
                      className={`font-bold ${
                        selectedContactData.netBalance > 0
                          ? 'text-emerald-600 dark:text-emerald-400'
                          : selectedContactData.netBalance < 0
                          ? 'text-rose-600 dark:text-rose-400'
                          : 'text-slate-500'
                      }`}
                    >
                      {selectedContactData.netBalance > 0
                        ? `Cần thu: +${new Intl.NumberFormat('vi-VN').format(selectedContactData.netBalance)} ₫`
                        : selectedContactData.netBalance < 0
                        ? `Cần trả: -${new Intl.NumberFormat('vi-VN').format(Math.abs(selectedContactData.netBalance))} ₫`
                        : '0 ₫'}
                    </span>
                  </p>
                </div>

                <div className="flex items-center gap-2">
                  <Button
                    size="sm"
                    variant="secondary"
                    onClick={() =>
                      onOpenLoanTransaction(
                        selectedContactData.contact,
                        selectedContactData.netBalance >= 0 ? 'repayment_received' : 'repayment_paid'
                      )
                    }
                  >
                    Trả / Thu nợ
                  </Button>
                  <Button
                    size="sm"
                    variant="primary"
                    onClick={() => onOpenLoanTransaction(selectedContactData.contact, 'lend')}
                  >
                    + Ghi nhận vay
                  </Button>
                  <button
                    onClick={() => onEditContact(selectedContactData.contact)}
                    className="p-1.5 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 rounded-lg hover:bg-slate-100 dark:hover:bg-slate-800"
                    title="Sửa liên hệ"
                  >
                    <Edit2 className="w-3.5 h-3.5" />
                  </button>
                  <button
                    onClick={() => {
                      if (confirm(`Xóa liên hệ "${selectedContactData.contact.name}"?`)) {
                        deleteLoanContact(selectedContactData.contact.cloud_id);
                        setSelectedContactId(null);
                      }
                    }}
                    className="p-1.5 text-slate-400 hover:text-rose-500 rounded-lg hover:bg-rose-50 dark:hover:bg-rose-950/30"
                    title="Xóa liên hệ"
                  >
                    <Trash2 className="w-3.5 h-3.5" />
                  </button>
                </div>
              </div>

              {/* Transaction timeline */}
              <div className="divide-y divide-slate-100 dark:divide-slate-800 max-h-[420px] overflow-y-auto">
                {selectedContactTxs.length === 0 ? (
                  <p className="text-xs text-slate-400 py-10 text-center">Chưa có giao dịch vay/trả nào</p>
                ) : (
                  selectedContactTxs.map((tx) => {
                    const isCredit = tx.type === 'lend' || tx.type === 'repayment_paid';
                    const typeLabel =
                      tx.type === 'lend'
                        ? 'Tôi cho vay'
                        : tx.type === 'borrow'
                        ? 'Tôi đi vay'
                        : tx.type === 'repayment_received'
                        ? 'Thu nợ thành công'
                        : 'Tôi đã trả nợ';

                    return (
                      <div
                        key={tx.cloud_id}
                        className="flex items-center justify-between p-4 hover:bg-slate-50 dark:hover:bg-slate-800/40"
                      >
                        <div>
                          <p className="text-xs font-semibold text-slate-900 dark:text-slate-100">
                            {typeLabel}
                          </p>
                          <p className="text-[11px] text-slate-400">
                            {tx.note ? `${tx.note} • ` : ''}
                            {new Date(tx.date).toLocaleString('vi-VN')}
                          </p>
                        </div>

                        <div className="flex items-center gap-3">
                          <span
                            className={`text-xs font-bold ${
                              isCredit
                                ? 'text-emerald-600 dark:text-emerald-400'
                                : 'text-rose-600 dark:text-rose-400'
                            }`}
                          >
                            {new Intl.NumberFormat('vi-VN').format(tx.amount)} ₫
                          </span>
                          <button
                            onClick={() => {
                              if (confirm('Xóa giao dịch này?')) {
                                deleteLoanTransaction(tx.cloud_id);
                              }
                            }}
                            className="p-1 text-slate-400 hover:text-rose-500 rounded-md"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </div>
          ) : (
            <div className="py-20 text-center text-slate-400 text-xs">
              Chọn một liên hệ từ danh sách bên trái để xem lịch sử nợ
            </div>
          )}
        </Card>
      </div>
    </div>
  );
};
