import { useState, useRef } from 'react';
import {
  FileSpreadsheet,
  Download,
  Upload,
  Printer,
  ShieldCheck,
  AlertCircle,
  CheckCircle2,
} from 'lucide-react';
import { useFinance } from '../contexts/FinanceContext';
import { Card, Button } from '../components/ui';
import { exportService } from '../services/exportService';

export const ExportBackupPage: React.FC = () => {
  const { transactions, categories, wallets } = useFinance();
  const fileInputRef = useRef<HTMLInputElement>(null);

  const [importStatus, setImportStatus] = useState<{
    success?: boolean;
    message?: string;
  } | null>(null);

  const handleExportCSV = () => {
    exportService.exportToCSV(transactions, categories, wallets);
  };

  const handleExportJSON = () => {
    exportService.exportDatabaseBackupJSON();
  };

  const handlePrint = () => {
    const catMap = new Map(categories.map((c) => [c.cloud_id, c.name]));
    const walletMap = new Map(wallets.map((w) => [w.cloud_id, w.name]));

    const rows = transactions.map(
      (t) => `
      <tr>
        <td>${t.date ? new Date(t.date).toLocaleDateString('vi-VN') : ''}</td>
        <td>${t.type === 'income' ? 'Thu' : 'Chi'}</td>
        <td class="${t.type === 'income' ? 'amount-income' : 'amount-expense'}">
          ${new Intl.NumberFormat('vi-VN').format(t.amount)} ₫
        </td>
        <td>${t.category_id ? catMap.get(t.category_id) || 'Khác' : ''}</td>
        <td>${t.wallet_id ? walletMap.get(t.wallet_id) || 'Ví' : ''}</td>
        <td>${t.note || ''}</td>
      </tr>
    `
    );

    const tableHtml = `
      <table>
        <thead>
          <tr>
            <th>Ngày</th>
            <th>Loại</th>
            <th>Số tiền</th>
            <th>Danh mục</th>
            <th>Tài khoản ví</th>
            <th>Ghi chú</th>
          </tr>
        </thead>
        <tbody>
          ${rows.join('')}
        </tbody>
      </table>
    `;

    exportService.printReport('Báo cáo Sổ Thu Chi - Simo Finance', tableHtml);
  };

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (evt) => {
      const content = evt.target?.result as string;
      const res = exportService.importDatabaseBackupJSON(content);
      setImportStatus(res);
      if (res.success) {
        setTimeout(() => window.location.reload(), 1500);
      }
    };
    reader.readAsText(file);
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-slate-900 dark:text-slate-100 tracking-tight">
          Xuất dữ liệu & Sao lưu dự phòng
        </h1>
        <p className="text-xs text-slate-500 dark:text-slate-400">
          Chủ động sao lưu, trích xuất dữ liệu ra file Excel/CSV hoặc phục hồi khi đổi máy
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Export Card */}
        <Card className="p-6 space-y-4">
          <div className="flex items-center gap-3 pb-3 border-b border-slate-100 dark:border-slate-800">
            <div className="w-9 h-9 rounded-xl bg-teal-50 dark:bg-teal-950/40 text-teal-600 dark:text-teal-400 flex items-center justify-center">
              <FileSpreadsheet className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
                Xuất file báo cáo
              </h3>
              <p className="text-[11px] text-slate-400">Tải dữ liệu thu chi ra bảng tính hoặc in ấn</p>
            </div>
          </div>

          <div className="space-y-3 pt-2">
            <div className="flex items-center justify-between p-3 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200/60 dark:border-slate-700/60">
              <div>
                <p className="text-xs font-semibold text-slate-900 dark:text-slate-100">
                  Xuất bảng tính CSV / Excel
                </p>
                <span className="text-[11px] text-slate-400">
                  Định dạng UTF-8 tương thích tốt với Microsoft Excel & Google Sheets
                </span>
              </div>
              <Button size="sm" variant="primary" onClick={handleExportCSV}>
                <Download className="w-3.5 h-3.5" />
                <span>Tải CSV</span>
              </Button>
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200/60 dark:border-slate-700/60">
              <div>
                <p className="text-xs font-semibold text-slate-900 dark:text-slate-100">
                  In sao kê / Xuất PDF
                </p>
                <span className="text-[11px] text-slate-400">
                  Mở giao diện in chuẩn văn bản để lưu file PDF hoặc in trực tiếp
                </span>
              </div>
              <Button size="sm" variant="outline" onClick={handlePrint}>
                <Printer className="w-3.5 h-3.5" />
                <span>In PDF</span>
              </Button>
            </div>
          </div>
        </Card>

        {/* Full Database Backup Card */}
        <Card className="p-6 space-y-4">
          <div className="flex items-center gap-3 pb-3 border-b border-slate-100 dark:border-slate-800">
            <div className="w-9 h-9 rounded-xl bg-indigo-50 dark:bg-indigo-950/40 text-indigo-600 dark:text-indigo-400 flex items-center justify-center">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
                Sao lưu & Khôi phục toàn bộ JSON
              </h3>
              <p className="text-[11px] text-slate-400">
                Lưu trữ toàn bộ 11 bảng dữ liệu (Ví, giao dịch, ngân sách, sổ nợ...)
              </p>
            </div>
          </div>

          <div className="space-y-3 pt-2">
            <div className="flex items-center justify-between p-3 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200/60 dark:border-slate-700/60">
              <div>
                <p className="text-xs font-semibold text-slate-900 dark:text-slate-100">
                  Tải bản sao lưu JSON
                </p>
                <span className="text-[11px] text-slate-400">
                  Lưu file .json đầy đủ về máy tính để lưu trữ offline
                </span>
              </div>
              <Button size="sm" variant="secondary" onClick={handleExportJSON}>
                <Download className="w-3.5 h-3.5" />
                <span>Tải Backup</span>
              </Button>
            </div>

            <div className="flex items-center justify-between p-3 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200/60 dark:border-slate-700/60">
              <div>
                <p className="text-xs font-semibold text-slate-900 dark:text-slate-100">
                  Phục hồi từ file JSON
                </p>
                <span className="text-[11px] text-slate-400">
                  Tải lên file backup .json đã lưu trước đó để ghi đè/phục hồi
                </span>
              </div>
              <div>
                <input
                  type="file"
                  accept=".json"
                  ref={fileInputRef}
                  onChange={handleFileChange}
                  className="hidden"
                />
                <Button
                  size="sm"
                  variant="outline"
                  onClick={() => fileInputRef.current?.click()}
                >
                  <Upload className="w-3.5 h-3.5" />
                  <span>Chọn File</span>
                </Button>
              </div>
            </div>

            {importStatus && (
              <div
                className={`p-3 rounded-xl flex items-center gap-2 text-xs ${
                  importStatus.success
                    ? 'bg-emerald-50 dark:bg-emerald-950/40 text-emerald-700 dark:text-emerald-300'
                    : 'bg-rose-50 dark:bg-rose-950/40 text-rose-700 dark:text-rose-300'
                }`}
              >
                {importStatus.success ? (
                  <CheckCircle2 className="w-4 h-4 shrink-0" />
                ) : (
                  <AlertCircle className="w-4 h-4 shrink-0" />
                )}
                <span>{importStatus.message}</span>
              </div>
            )}
          </div>
        </Card>
      </div>
    </div>
  );
};
