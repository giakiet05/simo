# Screen Audit & Consistency Matrix: SIMO

Tài liệu này tổng hợp kết quả đánh giá (Audit) toàn bộ 9 màn hình chính trong SIMO dựa trên bộ quy chuẩn **SIMO Design System**.

---

## 📋 1. Bảng Tổng hợp Mức độ Đồng bộ (Consistency Scorecard)

| Màn hình | Đường dẫn file | AppBar (+) | Card viền mờ | Chips cuộn ngang | Nhập tiền có dấu phẩy | Banner Ad ở đáy | Đánh giá chung |
|---|---|:---:|:---:|:---:|:---:|:---:|---|
| **1. Tổng quan (Dashboard)** | `lib/screens/dashboard_screen.dart` | N/A (Home) | ✅ | ✅ | ✅ | ✅ | **Chuẩn mực (98%)** |
| **2. Giao dịch (Transactions)** | `lib/screens/transaction_screen.dart` | N/A (Home) | ✅ | ✅ | ✅ | ✅ | **Chuẩn mực (95%)** |
| **3. Sổ nợ (Loans & Debts)** | `lib/screens/loan_screen.dart` | ✅ | ✅ | ✅ | ✅ | ✅ | **Chuẩn mực (98%)** |
| **4. Ngân sách & Danh mục** | `lib/screens/category_budget_screen.dart` | ✅ | ✅ | ✅ | ✅ | ✅ | **Chuẩn mực (96%)** |
| **5. Giao dịch định kỳ** | `lib/screens/recurring_screen.dart` | ✅ | ✅ | ✅ | ✅ | ✅ | **Chuẩn mực (96%)** |
| **6. Thống kê (Insights)** | `lib/screens/statistics_screen.dart` | ✅ | ✅ | ✅ | N/A | ✅ | **Chuẩn mực (97%)** |
| **7. Mục tiêu tiết kiệm** | `lib/screens/saving_goals_screen.dart` | ✅ | ✅ | ✅ | ✅ | ✅ | **Chuẩn mẫu Design System (100%)** |
| **8. Xuất & Sao lưu dữ liệu** | `lib/screens/export_backup_screen.dart` | N/A (Tab) | ✅ | ✅ | N/A | ✅ | **Chuẩn mực (98%)** |
| **9. Cài đặt (Settings)** | `lib/screens/settings_screen.dart` | N/A (Home) | ✅ | N/A | N/A | ✅ | **Chuẩn mực (95%)** |

---

## 🔍 2. Chi tiết Đánh giá Từng Màn hình

### 1. Dashboard (`lib/screens/dashboard_screen.dart`)
- **Điểm mạnh**:
  - `QuickAccessHub` bố trí 4 nút squircle tròn mềm mại với icon màu đại diện và nền làm mờ `0.1`.
  - Thẻ ngân sách tháng và tổng quan thu/chi rõ ràng, tương phản tốt trên cả Dark/Light mode.
- **Lưu ý đồng bộ**: Giữ kích thước các thẻ tổng quan nhỏ gọn để người dùng thấy ngay biểu đồ khi mở app.

---

### 2. Sổ nợ (`lib/screens/loan_screen.dart`)
- **Điểm mạnh**:
  - Nút thêm khoản vay đặt góc trên phải thanh AppBar.
  - Thẻ tổng hợp 2 cột: "Người ta nợ mình" (Xanh) vs "Mình nợ người ta" (Đỏ/Cam).
  - Modal tạo và thanh toán nợ có định dạng dấu phẩy hàng nghìn.

---

### 3. Ngân sách & Danh mục (`lib/screens/category_budget_screen.dart`)
- **Điểm mạnh**:
  - Chọn tháng linh hoạt (Đa tháng độc lập), hỗ trợ sao chép ngân sách tháng trước.
  - Các thẻ danh mục hiển thị thanh tiến độ `LinearProgressIndicator` đổi màu theo tỷ lệ chi tiêu (Xanh lá < 80%, Hổ phách 80-100%, Đỏ > 100%).

---

### 4. Mục tiêu tiết kiệm (`lib/screens/saving_goals_screen.dart` & `saving_goal_detail_screen.dart`)
- **Điểm mạnh**:
  - **Chuẩn mẫu 100%** của Design System mới.
  - Thẻ Hero Overview tính tổng tiền đã gom và biểu đồ tròn % tiến độ.
  - Hàng chip lọc bọc trong `SingleChildScrollView(scrollDirection: Axis.horizontal)`.
  - Mọi ô nhập tiền đều tự động định dạng `1,000,000` theo thời gian thực.
  - Màn hình chi tiết có 2 nút Nạp/Rút nổi bật và timeline lịch sử có nút xóa trực tiếp.

---

### 5. Xuất & Sao lưu (`lib/screens/export_backup_screen.dart`)
- **Điểm mạnh**:
  - Bố cục 2 Tab rõ ràng: Tab 1 chọn khoảng thời gian + chọn định dạng (Excel, PDF, CSV) -> 1 nút "Xuất file" duy nhất ở đáy.
  - Tab 2 có 2 thẻ hành động: "Tạo bản sao lưu" và "Khôi phục dữ liệu" không dùng từ ngữ kỹ thuật rườm rà.

---

## 🎯 3. Danh mục Kiểm tra Khi Tạo Màn hình Mới (Checklist)

Khi phát triển thêm bất kỳ màn hình hoặc tính năng mới nào, hãy kiểm tra lần lượt:

- [ ] 1. **AppBar**: `elevation: 0`, nút tạo mới `+` đặt ở `actions` góc trên phải.
- [ ] 2. **Hero Overview (nếu có)**: Bo góc `20dp`, nền `primary.withValues(alpha: 0.05)`, viền `0.2`.
- [ ] 3. **List Cards**: Bo góc `16dp`, viền `Colors.grey.withValues(alpha: 0.15 - 0.20)`.
- [ ] 4. **Chips lọc**: Luôn bọc trong `SingleChildScrollView(scrollDirection: Axis.horizontal)`.
- [ ] 5. **Ô nhập tiền tệ**: Áp dụng `CurrencyInputFormatter`, `keyboardType: TextInputType.number`.
- [ ] 6. **Form BottomSheet**: Bo góc đỉnh `20dp`, đệm `viewInsets.bottom`, nút lưu `double.infinity`.
- [ ] 7. **Empty State**: Hiển thị icon mờ ở giữa màn hình + mô tả + nút tạo khi danh sách rỗng.
- [ ] 8. **Banner Ad**: Đặt `const BannerAdWidget()` ở đáy màn hình bên dưới `Expanded`.
