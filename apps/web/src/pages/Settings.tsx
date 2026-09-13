import { useState } from 'react';
import {
  Sun,
  Moon,
  Coins,
  Globe,
  Database,
  Trash2,
  Plus,
  Edit2,
  Sparkles,
  Tag,
  CheckCircle2,
} from 'lucide-react';
import { useFinance } from '../contexts/FinanceContext';
import { useTheme } from '../contexts/ThemeContext';
import { Card, Button } from '../components/ui';
import { localDb } from '../services/db';
import type { Category } from '../types';

interface SettingsPageProps {
  onOpenCategoryModal: (cat?: Category | null) => void;
}

export const SettingsPage: React.FC<SettingsPageProps> = ({ onOpenCategoryModal }) => {
  const { categories, deleteCategory } = useFinance();
  const { theme, setTheme } = useTheme();

  const [mockLoading, setMockLoading] = useState(false);
  const [successMsg, setSuccessMsg] = useState<string | null>(null);

  const expenseCategories = categories.filter((c) => c.type === 'expense');
  const incomeCategories = categories.filter((c) => c.type === 'income');

  const handleGenerateMockData = async () => {
    if (!confirm('Tạo bộ dữ liệu mẫu (ví, danh mục, 30+ giao dịch trong 3 tháng gần nhất)?')) {
      return;
    }
    setMockLoading(true);

    try {
      const state = localDb.loadState();
      const now = new Date();

      // Ensure wallets
      if (state.wallets.length === 0) {
        state.wallets = [
          {
            id: 'w-cash',
            cloud_id: 'w-cash',
            name: 'Tiền mặt',
            balance: 3500000,
            currency: 'VND',
            type: 'cash',
            icon: 'Wallet',
            color: '#10B981',
            is_default: true,
            exclude_from_total: false,
            synced: 0,
            updated_at: now.toISOString(),
          },
          {
            id: 'w-bank',
            cloud_id: 'w-bank',
            name: 'Techcombank',
            balance: 42000000,
            currency: 'VND',
            type: 'bank',
            icon: 'Building2',
            color: '#3B82F6',
            is_default: false,
            exclude_from_total: false,
            synced: 0,
            updated_at: now.toISOString(),
          },
        ];
      }

      // Generate 25 sample transactions
      const sampleNotes = [
        { note: 'Ăn trưa cơm văn phòng', amount: 45000, type: 'expense', cat: 'Ăn uống' },
        { note: 'Uống cà phê sáng', amount: 35000, type: 'expense', cat: 'Ăn uống' },
        { note: 'Đổ xăng xe máy', amount: 90000, type: 'expense', cat: 'Di chuyển' },
        { note: 'Siêu thị Winmart', amount: 320000, type: 'expense', cat: 'Ăn uống' },
        { note: 'Thanh toán tiền điện', amount: 650000, type: 'expense', cat: 'Hóa đơn & Tiện ích' },
        { note: 'Tiền mạng Internet', amount: 220000, type: 'expense', cat: 'Hóa đơn & Tiện ích' },
        { note: 'Nhận lương tháng', amount: 25000000, type: 'income', cat: 'Lương' },
        { note: 'Thưởng dự án', amount: 3000000, type: 'income', cat: 'Thưởng' },
        { note: 'Mua sắm quần áo Uniqlo', amount: 890000, type: 'expense', cat: 'Mua sắm' },
        { note: 'Đi xem phim CGV', amount: 210000, type: 'expense', cat: 'Ăn uống' },
      ];

      const newTxs = [];
      for (let i = 0; i < 25; i++) {
        const item = sampleNotes[i % sampleNotes.length];
        const daysAgo = Math.floor(Math.random() * 60);
        const txDate = new Date(Date.now() - daysAgo * 86400000).toISOString();
        const cat = state.categories.find((c) => c.name === item.cat) || state.categories[0];
        const wal = state.wallets[0];

        const id = 'mock-' + Math.random().toString(36).substring(2, 10);
        newTxs.push({
          id,
          cloud_id: id,
          wallet_id: wal?.cloud_id,
          category_id: cat?.cloud_id,
          type: item.type as any,
          amount: item.amount + Math.floor(Math.random() * 5) * 5000,
          date: txDate,
          note: item.note,
          synced: 0,
          updated_at: now.toISOString(),
        });
      }

      state.transactions = [...newTxs, ...state.transactions];
      localDb.saveAll(state);
      setSuccessMsg('Đã tạo dữ liệu mẫu thành công!');
      setTimeout(() => window.location.reload(), 1200);
    } catch (err: any) {
      alert('Lỗi tạo dữ liệu: ' + err.message);
    } finally {
      setMockLoading(false);
    }
  };

  const handleClearLocalData = () => {
    if (confirm('CẢNH BÁO: Thao tác này sẽ xóa sạch toàn bộ dữ liệu lưu trên trình duyệt của máy này. Bạn có chắc chắn?')) {
      localDb.clearAll();
      window.location.reload();
    }
  };

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Header */}
      <div>
        <h1 className="text-xl font-bold text-slate-900 dark:text-slate-100 tracking-tight">
          Cài đặt & Tùy biến hệ thống
        </h1>
        <p className="text-xs text-slate-500 dark:text-slate-400">
          Quản lý giao diện, danh mục chi tiêu, công cụ nhà phát triển và dữ liệu ứng dụng
        </p>
      </div>

      {successMsg && (
        <div className="p-3 bg-emerald-50 dark:bg-emerald-950/40 border border-emerald-200 dark:border-emerald-800 text-emerald-700 dark:text-emerald-300 rounded-xl text-xs flex items-center gap-2">
          <CheckCircle2 className="w-4 h-4" />
          <span>{successMsg}</span>
        </div>
      )}

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {/* Appearance Card */}
        <Card className="p-6 space-y-4">
          <div className="flex items-center gap-3 pb-3 border-b border-slate-100 dark:border-slate-800">
            <Sun className="w-5 h-5 text-amber-500" />
            <div>
              <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">Giao diện (Theme)</h3>
              <p className="text-[11px] text-slate-400">Tùy chọn nền trắng hoặc chế độ ban đêm</p>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-2 pt-1">
            <button
              onClick={() => setTheme('light')}
              className={`p-3 rounded-xl border text-xs font-semibold flex flex-col items-center gap-2 transition-all cursor-pointer ${
                theme === 'light'
                  ? 'border-teal-600 bg-teal-50 dark:bg-teal-950/40 text-teal-700 dark:text-teal-300'
                  : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800'
              }`}
            >
              <Sun className="w-4 h-4 text-amber-500" />
              <span>Nền sáng (Trắng)</span>
            </button>
            <button
              onClick={() => setTheme('dark')}
              className={`p-3 rounded-xl border text-xs font-semibold flex flex-col items-center gap-2 transition-all cursor-pointer ${
                theme === 'dark'
                  ? 'border-teal-600 bg-teal-50 dark:bg-teal-950/40 text-teal-700 dark:text-teal-300'
                  : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800'
              }`}
            >
              <Moon className="w-4 h-4 text-indigo-400" />
              <span>Nền tối (Dark)</span>
            </button>
            <button
              onClick={() => setTheme('system')}
              className={`p-3 rounded-xl border text-xs font-semibold flex flex-col items-center gap-2 transition-all cursor-pointer ${
                theme === 'system'
                  ? 'border-teal-600 bg-teal-50 dark:bg-teal-950/40 text-teal-700 dark:text-teal-300'
                  : 'border-slate-200 dark:border-slate-700 hover:bg-slate-50 dark:hover:bg-slate-800'
              }`}
            >
              <Globe className="w-4 h-4 text-teal-500" />
              <span>Theo hệ thống</span>
            </button>
          </div>
        </Card>

        {/* Currency & Locale */}
        <Card className="p-6 space-y-4">
          <div className="flex items-center gap-3 pb-3 border-b border-slate-100 dark:border-slate-800">
            <Coins className="w-5 h-5 text-teal-600" />
            <div>
              <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">Tiền tệ & Ngôn ngữ</h3>
              <p className="text-[11px] text-slate-400">Định dạng hiển thị con số và bản địa hóa</p>
            </div>
          </div>

          <div className="space-y-3 pt-1">
            <div className="flex justify-between items-center text-xs">
              <span className="text-slate-600 dark:text-slate-400">Đơn vị tiền tệ chính:</span>
              <span className="font-bold text-slate-900 dark:text-slate-100">Việt Nam Đồng (VND - ₫)</span>
            </div>
            <div className="flex justify-between items-center text-xs">
              <span className="text-slate-600 dark:text-slate-400">Ngôn ngữ hiển thị:</span>
              <span className="font-bold text-slate-900 dark:text-slate-100">Tiếng Việt (vi-VN)</span>
            </div>
          </div>
        </Card>
      </div>

      {/* Categories Management */}
      <Card className="p-6 space-y-4">
        <div className="flex items-center justify-between pb-3 border-b border-slate-100 dark:border-slate-800">
          <div className="flex items-center gap-3">
            <Tag className="w-5 h-5 text-teal-600" />
            <div>
              <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">
                Danh mục thu chi ({categories.length})
              </h3>
              <p className="text-[11px] text-slate-400">Thêm, sửa đổi hoặc phân loại các nhóm thu chi</p>
            </div>
          </div>
          <Button size="sm" variant="primary" onClick={() => onOpenCategoryModal(null)}>
            <Plus className="w-3.5 h-3.5" />
            <span>Thêm danh mục</span>
          </Button>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 gap-6 pt-2">
          {/* Expense Categories */}
          <div className="space-y-2">
            <h4 className="text-xs font-bold text-rose-600 dark:text-rose-400 uppercase tracking-wider">
              Danh mục Chi tiêu ({expenseCategories.length})
            </h4>
            <div className="space-y-1.5 max-h-56 overflow-y-auto pr-1">
              {expenseCategories.map((c) => (
                <div
                  key={c.cloud_id}
                  className="flex items-center justify-between p-2 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200/60 dark:border-slate-700/60 text-xs"
                >
                  <div className="flex items-center gap-2">
                    <div
                      className="w-3.5 h-3.5 rounded-full"
                      style={{ backgroundColor: c.color || '#F97316' }}
                    />
                    <span className="font-semibold text-slate-800 dark:text-slate-200">{c.name}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => onOpenCategoryModal(c)}
                      className="p-1 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 rounded-md"
                    >
                      <Edit2 className="w-3 h-3" />
                    </button>
                    <button
                      onClick={() => {
                        if (confirm(`Xóa danh mục "${c.name}"?`)) {
                          deleteCategory(c.cloud_id);
                        }
                      }}
                      className="p-1 text-slate-400 hover:text-rose-500 rounded-md"
                    >
                      <Trash2 className="w-3 h-3" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>

          {/* Income Categories */}
          <div className="space-y-2">
            <h4 className="text-xs font-bold text-emerald-600 dark:text-emerald-400 uppercase tracking-wider">
              Danh mục Thu nhập ({incomeCategories.length})
            </h4>
            <div className="space-y-1.5 max-h-56 overflow-y-auto pr-1">
              {incomeCategories.map((c) => (
                <div
                  key={c.cloud_id}
                  className="flex items-center justify-between p-2 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200/60 dark:border-slate-700/60 text-xs"
                >
                  <div className="flex items-center gap-2">
                    <div
                      className="w-3.5 h-3.5 rounded-full"
                      style={{ backgroundColor: c.color || '#10B981' }}
                    />
                    <span className="font-semibold text-slate-800 dark:text-slate-200">{c.name}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <button
                      onClick={() => onOpenCategoryModal(c)}
                      className="p-1 text-slate-400 hover:text-slate-700 dark:hover:text-slate-200 rounded-md"
                    >
                      <Edit2 className="w-3 h-3" />
                    </button>
                    <button
                      onClick={() => {
                        if (confirm(`Xóa danh mục "${c.name}"?`)) {
                          deleteCategory(c.cloud_id);
                        }
                      }}
                      className="p-1 text-slate-400 hover:text-rose-500 rounded-md"
                    >
                      <Trash2 className="w-3 h-3" />
                    </button>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </Card>

      {/* Developer & Danger Zone */}
      <Card className="p-6 space-y-4">
        <div className="flex items-center gap-3 pb-3 border-b border-slate-100 dark:border-slate-800">
          <Database className="w-5 h-5 text-indigo-500" />
          <div>
            <h3 className="text-sm font-bold text-slate-900 dark:text-slate-100">Dữ liệu & Sandbox</h3>
            <p className="text-[11px] text-slate-400">Công cụ hỗ trợ thử nghiệm và quản trị local cache</p>
          </div>
        </div>

        <div className="flex flex-wrap items-center justify-between gap-4 pt-1">
          <div>
            <p className="text-xs font-semibold text-slate-900 dark:text-slate-100">Tạo dữ liệu mẫu (Mock Data)</p>
            <span className="text-[11px] text-slate-400">
              Tạo tự động 25 giao dịch, ví tiền và ngân sách để kiểm thử giao diện
            </span>
          </div>
          <Button size="sm" variant="secondary" onClick={handleGenerateMockData} isLoading={mockLoading}>
            <Sparkles className="w-3.5 h-3.5" />
            <span>Tạo dữ liệu mẫu</span>
          </Button>
        </div>

        <div className="flex flex-wrap items-center justify-between gap-4 pt-3 border-t border-slate-100 dark:border-slate-800">
          <div>
            <p className="text-xs font-semibold text-rose-600 dark:text-rose-400">Xóa trắng bộ nhớ tạm (Reset Cache)</p>
            <span className="text-[11px] text-slate-400">
              Xóa toàn bộ dữ liệu đang lưu trong IndexedDB / LocalStorage của trình duyệt này
            </span>
          </div>
          <Button size="sm" variant="danger" onClick={handleClearLocalData}>
            <Trash2 className="w-3.5 h-3.5" />
            <span>Xóa Local DB</span>
          </Button>
        </div>
      </Card>
    </div>
  );
};
