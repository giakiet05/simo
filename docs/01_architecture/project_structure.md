# Cấu Trúc Dự Án (Project Structure & Directory Map)

Tài liệu này mô tả chi tiết cây thư mục của mã nguồn Simo (`lib/`), quy ước đặt tên và trách nhiệm của từng tầng code.

---

## 1. Sơ Đồ Cây Thư Mục Tổng Quan (`lib/`)

```text
lib/
├── config/                  # Cấu hình môi trường (API Keys, Supabase, AdMob, Flavors)
├── models/                  # Domain Entities & Immutable Data Models
├── providers/               # Riverpod State Management & Notifiers
├── repositories/            # Data Access Object (DAO) & SQLite Queries
├── screens/                 # Các màn hình chính (Full-page views)
├── services/                # Nghiệp vụ domain độc lập & tích hợp bên thứ ba
├── theme/                   # Design Tokens (Màu sắc, Typography, AppTheme)
├── utils/                   # Hàm tiện ích, Constant, Formatters, Regex
├── widgets/                 # Reusable UI Components & Modals
└── main.dart                # Entry point khởi tạo App, Database & Providers
```

---

## 2. Chi Tiết Trách Nhiệm Từng Thư Mục

### 2.1. `lib/models/` (Data Models)
Chứa các Dart class đại diện cho các thực thể dữ liệu trong hệ thống.
- **Quy tắc**:
  - 100% Immutable (`final` fields).
  - Có các hàm `toMap()` và `fromMap(Map<String, dynamic>)` phục vụ SQLite mapping.
  - Có hàm `copyWith(...)` hỗ trợ biến đổi trạng thái an toàn.
- **Danh sách models chính**:
  - `wallet.dart`: Ví tiền (id, name, type, initial_balance, current_balance, currency, priority, is_default).
  - `wallet_transfer.dart`: Lịch sử giao dịch chuyển tiền giữa 2 ví nội bộ.
  - `transaction.dart`: Giao dịch thu/chi (amount, type, category_id, wallet_id, transaction_date).
  - `category.dart`: Danh mục thu/chi (id, name, type, icon, color, budget_limit).
  - `monthly_budget.dart`: Ngân sách tổng tháng & hạn mức danh mục (`CategoryBudgetStatus`, `MonthYearKey`).
  - `saving_goal.dart` & `saving_goal_log.dart`: Mục tiêu tiết kiệm và lịch sử gửi/rút.
  - `loan_contact.dart` & `loan_transaction.dart`: Sổ nợ (người vay/cho vay và các đợt trả).
  - `backup_snapshot.dart` & `import_inspection.dart`: Cấu trúc JSON backup và kiểm tra tính toàn vẹn khi import.
  - `settings.dart`: Cài đặt cá nhân (theme_mode, currency, language, notification).

### 2.2. `lib/repositories/` (Data Access Layer)
Đóng vai trò cầu nối duy nhất giữa ứng dụng và cơ sở dữ liệu cục bộ SQLite.
- `database_helper.dart`: Quản lý mở kết nối `simo.db`, thực thi migration v1 đến v16, cung cấp phương thức `clearAllData()`.
- `wallet_repository.dart`: Thao tác CRUD ví, atomic transfers `transferFunds()`, tính lại số dư `recalculateWalletBalance()`.
- `transaction_repository.dart`: Thao tác CRUD giao dịch, tự động cập nhật số dư ví liên quan, truy vấn theo khoảng thời gian/bộ lọc.
- `category_repository.dart`: Quản lý danh mục, xử lý xóa danh mục (gán `category_id = NULL` cho các giao dịch liên quan để không mất dữ liệu).
- `monthly_budget_repository.dart`: Quản lý bảng `monthly_budgets` và `category_monthly_budgets`.
- `saving_goal_repository.dart`: Quản lý mục tiêu tiết kiệm và logs.
- `loan_repository.dart`: Quản lý sổ nợ, tự động cập nhật `remaining_amount` và trạng thái `completed`.

### 2.3. `lib/providers/` (State Management Layer)
Sử dụng **Riverpod 2.x** để kết nối UI và Repositories.
- `wallet_provider.dart`: State danh sách ví (`walletListProvider`), tổng tài sản (`totalBalanceProvider`).
- `transaction_provider.dart`: Quản lý danh sách giao dịch gần đây, phân trang, lọc theo tiêu chí.
- `category_provider.dart`: Quản lý danh mục thu/chi (`categoriesProvider`, `expenseCategoriesProvider`, `incomeCategoriesProvider`).
- `monthly_budget_provider.dart`: Cung cấp `monthlyBudgetFamily(MonthYearKey)` để quản lý ngân sách riêng cho từng tháng/năm.
- `saving_goal_provider.dart`: State danh sách mục tiêu tiết kiệm.
- `loan_provider.dart`: State danh bạ nợ và lịch sử thanh toán.
- `settings_provider.dart` & `localization_provider.dart`: State cấu hình ứng dụng, đa ngôn ngữ (vi/en).

### 2.4. `lib/screens/` (Màn Hình Ứng Dụng)
Chứa các view cấp cao nhất tương ứng với các tuyến điều hướng trong ứng dụng:
- `home_screen.dart`: Màn hình tổng quan (Tổng số dư, Biểu đồ thu chi tuần/tháng, Danh sách giao dịch gần đây).
- `transaction_history_screen.dart`: Lịch sử giao dịch chi tiết, tìm kiếm mờ, bộ lọc đa tiêu chí.
- `transaction_form_screen.dart`: Màn hình tạo mới và chỉnh sửa giao dịch (chọn ví ngang, quick date bar, category grid).
- `category_budget_screen.dart`: Màn hình "Danh mục & Hạn mức", xem tiến độ chi tiêu theo tháng, đặt hạn mức từng mục.
- `wallets_screen.dart` & `wallet_detail_screen.dart`: Quản lý danh sách ví, xem sao kê từng ví, chuyển tiền nội bộ.
- `saving_goals_screen.dart` & `saving_goal_detail_screen.dart`: Danh sách và chi tiết mục tiêu tiết kiệm.
- `loans_screen.dart` & `loan_detail_screen.dart`: Sổ ghi nợ, chi tiết từng khoản vay, lịch sử trả.
- `features_screen.dart`: Danh mục các tính năng phụ trợ (Ngân sách, Mục tiêu, Sổ nợ, Xuất dữ liệu).
- `settings_screen.dart`: Cài đặt tiền tệ, giao diện, backup/restore, bảo mật.

### 2.5. `lib/widgets/` (Reusable Components)
Tách nhỏ các thành phần giao diện để tái sử dụng và kiểm thử độc lập:
- `category_form_modal.dart`: Modal tạo/sửa danh mục với Live Preview, bảng màu, chọn icon, và Sticky Action Bar.
- `wallet_form_modal.dart`: Modal tạo/sửa ví, chọn đơn vị tiền tệ, cài đặt độ ưu tiên `priority`.
- `wallet_transfer_modal.dart`: Modal chuyển tiền giữa 2 ví, nhập phí chuyển.
- `transaction/`:
  - `wallet_chip_selector.dart`: Thanh cuộn ngang chọn ví theo độ ưu tiên.
  - `date_quick_bar.dart`: Thanh chọn nhanh ngày (Hôm nay, Hôm qua, Ngày khác).
  - `category_grid_picker.dart`: Lưới chọn danh mục thu/chi.
  - `transaction_detail_bottom_sheet.dart`: Bottom sheet xem chi tiết giao dịch với 2 nút Xóa / Chỉnh sửa cố định.

### 2.6. `lib/services/` (Domain & Infrastructure Services)
- `ai_transaction_service.dart`: Gọi OpenAI API để phân tích cú pháp câu nói thành JSON giao dịch.
- `ai_action_dispatcher.dart`: Điều hướng action do AI đề xuất vào hệ thống.
- `currency_service.dart`: Quản lý ký hiệu tiền tệ (`VND`, `USD`, `EUR`...), tỷ giá quy đổi, format số tiền.
- `backup_service.dart`: Tạo file snapshot JSON sao lưu toàn bộ dữ liệu SQLite, mã hóa/giải mã, khôi phục dữ liệu.
- `export_service.dart`: Kết xuất dữ liệu sang định dạng Excel (`.xlsx`), CSV (`.csv`), hoặc PDF in ấn.
- `fuzzy_search_service.dart`: Thuật toán tìm kiếm xấp xỉ không dấu tiếng Việt cho giao dịch và danh mục.
- `rewarded_ad_service.dart`: Tích hợp Google Mobile Ads xem video thưởng gỡ quảng cáo 12 tiếng.

### 2.7. `lib/theme/` & `lib/utils/`
- `theme/app_colors.dart`: Bảng mã màu chuẩn (Slate 900 `#0F172A`, Primary Emerald `#10B981`, Expense Red `#EF4444`...).
- `utils/app_constants.dart`: Giới hạn số tiền tối đa (`maxAmount`), cấu hình mặc định.
- `utils/currency_input_formatter.dart`: Formatter tự động chèn dấu phẩy ngăn cách hàng nghìn khi người dùng gõ số tiền.
- `utils/icon_data.dart`: Bản đồ ánh xạ giữa mã icon string và `IconData` của Material Icons.
