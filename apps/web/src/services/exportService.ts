import type { Transaction, Category, Wallet, LocalDatabaseState } from '../types';
import { localDb } from './db';

export const exportService = {
  exportToCSV: (
    transactions: Transaction[],
    categories: Category[],
    wallets: Wallet[],
    fileName = 'simo_transactions_export.csv'
  ) => {
    const catMap = new Map(categories.map((c) => [c.cloud_id, c.name]));
    const walletMap = new Map(wallets.map((w) => [w.cloud_id, w.name]));

    const headers = ['Mã Giao Dịch', 'Ngày', 'Loại', 'Số Tiền', 'Danh Mục', 'Tài Khoản / Ví', 'Ghi Chú'];
    const rows = transactions.map((t) => [
      t.cloud_id,
      t.date ? new Date(t.date).toLocaleString('vi-VN') : '',
      t.type === 'income' ? 'Thu nhập' : t.type === 'expense' ? 'Chi tiêu' : t.type,
      t.amount,
      t.category_id ? catMap.get(t.category_id) || 'Khác' : 'Không có',
      t.wallet_id ? walletMap.get(t.wallet_id) || 'Ví' : 'Không có',
      `"${(t.note || '').replace(/"/g, '""')}"`,
    ]);

    const csvContent = '\uFEFF' + [headers.join(','), ...rows.map((r) => r.join(','))].join('\r\n');
    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', fileName);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  },

  exportDatabaseBackupJSON: () => {
    const state = localDb.loadState();
    const backup = {
      app: 'Simo Personal Finance',
      version: '1.2.0',
      exported_at: new Date().toISOString(),
      data: state,
    };
    const jsonString = JSON.stringify(backup, null, 2);
    const blob = new Blob([jsonString], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.setAttribute('href', url);
    link.setAttribute('download', `simo_backup_${new Date().toISOString().split('T')[0]}.json`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);
  },

  importDatabaseBackupJSON: (jsonString: string): { success: boolean; message: string; count?: number } => {
    try {
      const parsed = JSON.parse(jsonString);
      const data: LocalDatabaseState = parsed.data || parsed;
      if (!data.transactions || !data.wallets) {
        throw new Error('Định dạng file sao lưu không hợp lệ. Thiếu bảng dữ liệu cần thiết.');
      }
      localDb.saveAll(data);
      return {
        success: true,
        message: 'Khôi phục dữ liệu thành công!',
        count: data.transactions.length,
      };
    } catch (err: any) {
      return {
        success: false,
        message: err.message || 'Lỗi khi đọc file backup JSON',
      };
    }
  },

  printReport: (title: string, htmlContent: string) => {
    const win = window.open('', '_blank');
    if (!win) return;
    win.document.write(`
      <html>
        <head>
          <title>${title}</title>
          <style>
            body { font-family: system-ui, -apple-system, sans-serif; padding: 24px; color: #1e293b; }
            h1 { font-size: 20px; font-weight: bold; margin-bottom: 8px; }
            table { width: 100%; border-collapse: collapse; margin-top: 16px; font-size: 12px; }
            th, td { border: 1px solid #cbd5e1; padding: 8px; text-align: left; }
            th { background-color: #f1f5f9; }
            .amount-income { color: #16a34a; font-weight: 600; }
            .amount-expense { color: #e11d48; font-weight: 600; }
          </style>
        </head>
        <body>
          <h1>${title}</h1>
          <p style="font-size: 11px; color: #64748b;">Thời gian in: ${new Date().toLocaleString('vi-VN')}</p>
          ${htmlContent}
        </body>
      </html>
    `);
    win.document.close();
    win.print();
  },
};
