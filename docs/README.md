# Tài Liệu Kỹ Thuật Simo (Simo Engineering Documentation)

Chào mừng bạn đến với trung tâm tài liệu kỹ thuật của dự án **Simo** — Ứng dụng quản lý tài chính cá nhân đa nền tảng hiện đại, được xây dựng theo triết lý **Offline-First & Privacy-First**.

---

## 1. Bản Đồ Tài Liệu (Documentation Map)

Toàn bộ tài liệu được phân chia thành các chủ đề chuyên sâu, bạn có thể truy cập nhanh theo danh mục dưới đây:

### 📐 01. Kiến Trúc Hệ Thống (Architecture)
- [**Kiến trúc tổng quan & Triết lý thiết kế**](01_architecture/overview.md): Mục tiêu dự án, tech stack chiến lược, mô hình phân tầng (Layered Architecture), và luồng dữ liệu chuẩn.
- [**Kiến trúc Đồng bộ Offline-First (Sync Engine)**](01_architecture/offline_first_sync_architecture.md): So sánh Online-First vs Offline-First, 5 trụ cột kỹ thuật, giải pháp 5 Edge Cases kinh điển và sơ đồ tuần tự chi tiết.
- [**Cấu trúc thư mục & Bản đồ mã nguồn**](01_architecture/project_structure.md): Chi tiết trách nhiệm của từng thư mục trong `lib/` (Models, Repositories, Providers, Screens, Services, Widgets).
- [**Quản lý trạng thái với Riverpod**](01_architecture/state_management.md): Notifier, Family Providers (`monthlyBudgetFamily`), cơ chế xử lý bất đồng bộ (`AsyncValue`), và quy trình vô hiệu hóa cache (Invalidation flow).

### 🗄️ 02. Dữ Liệu & Lưu Trữ (Data & Storage)
- [**Lược đồ cơ sở dữ liệu SQLite**](02_data_and_storage/database_schema.md): Sơ đồ ERD quan hệ thực thể, đặc tả 11 bảng dữ liệu, và toàn bộ lịch sử Migration từ v1 đến v16.
- [**Cơ chế DatabaseHelper & Repository Pattern**](02_data_and_storage/database_helper_and_repos.md): Xử lý kết nối Singleton, giao dịch ACID đơn nguyên (`transferFunds`, soft-unlink khi xóa category), và kiểm soát concurrency.
- [**Đồng bộ Đám mây & Sao lưu Snapshot JSON**](02_data_and_storage/cloud_and_sync.md): Cấu trúc tệp sao lưu JSON, quy trình kiểm tra toàn vẹn (Import inspection), và kiến trúc Two-Way Delta Sync.

### 💡 03. Đặc Tả Nghiệp Vụ Cốt Lõi (Core Features)
- [**Ví tiền & Chuyển tiền nội bộ**](03_core_features/wallets_and_transfers.md): Quản lý đa ví, tính năng chuyển tiền Atomic giữa 2 ví, và cơ chế sắp xếp ví theo độ ưu tiên `priority`.
- [**Giao dịch & Danh mục thu chi**](03_core_features/transactions_and_categories.md): Form nhập liệu tối ưu (thanh ví ngang, chọn ngày nhanh), danh mục hệ thống vs người dùng, và nhập liệu giọng nói AI.
- [**Ngân sách hàng tháng & Hạn mức chi tiêu**](03_core_features/monthly_budgets_and_limits.md): Cơ chế 2 tầng ngân sách, Sticky Bottom Action Bar, và quy tắc kế thừa hạn mức (tháng hiện tại/tương lai vs tháng quá khứ).
- [**Mục tiêu tiết kiệm**](03_core_features/saving_goals.md): Vòng đời mục tiêu (Active -> Completed), nạp rút tiền liên kết với ví, và lịch sử logs.
- [**Sổ ghi nợ & Cho vay**](03_core_features/loans_and_debts.md): Quản lý người vay/cho vay, ghi nhận thanh toán từng phần, và tự động tất toán khoản nợ.

### 🎨 04. Hệ Thống Giao Diện (Design System)
- [**Design System Overview**](design_system/README.md): Giới thiệu hệ thống thiết kế giao diện Simo.
- [**Design Tokens**](design_system/tokens.md): Bảng mã màu (`AppColors`), khoảng cách (spacing), bán kính bo góc (border radius), và kiểu chữ (typography).
- [**UI Components**](design_system/components.md): Hướng dẫn sử dụng các widget chuẩn: Buttons, Cards, BottomSheets, TextFields.
- [**Design Recipes**](design_system/recipes.md): Các mẫu thiết kế UI chuẩn cho danh sách, modal và form.
- [**Screen Audit**](design_system/screen_audit.md): Đánh giá hiện trạng giao diện của từng màn hình.

### 🚀 05. Vận Hành & Kiểm Thử (DevOps & Testing)
- [**Hướng dẫn Build, Flavors & Phát hành**](05_devops_and_testing/build_and_flavors.md): Phân biệt bản Dev (`Simo Dev`) và Production, script đóng gói có/không quảng cáo (`build_with_ads.sh`, `build_no_ads.sh`).
- [**Hướng dẫn Kiểm thử & Chất lượng mã nguồn**](05_devops_and_testing/testing_guide.md): Cấu hình `sqflite_common_ffi`, quy tắc vàng `--concurrency=1`, và chạy static linter.

---

## 2. Hướng Dẫn Bắt Đầu Nhanh (Developer Quickstart)

### 2.1. Yêu cầu môi trường
- **Flutter SDK**: `^3.10.1` (kiểm tra bằng `flutter --version`).
- **Dart SDK**: `^3.10.1`.
- **Hệ điều hành**: Linux (EndeavourOS, Ubuntu), macOS, hoặc Windows.

### 2.2. Khởi tạo dự án
```bash
# 1. Cài đặt các dependencies
flutter pub get

# 2. Kiểm tra chất lượng mã nguồn
flutter analyze

# 3. Chạy bộ kiểm thử tự động
flutter test --concurrency=1

# 4. Khởi chạy ứng dụng bản Dev trên thiết bị Android
flutter run -d <DEVICE_ID>
```

---

## 3. Quy Chuẩn Kỹ Thuật Khi Đóng Góp Code (Contribution Rules)
- **100% Tiếng Anh trong Codebase**: Tên biến, tên hàm, class, comment, commit message đều dùng tiếng Anh.
- **Không Emoji trong Code**: Nghiêm cấm đặt emoji trong mã nguồn, comment, hoặc log.
- **Viết Test Đi Kèm**: Mọi logic hoặc tính năng mới bắt buộc phải có Unit/Widget Test.
- **Quy tắc xóa dữ liệu**: Tuyệt đối không xóa cứng các giao dịch lịch sử khi xóa danh mục hoặc ví.
