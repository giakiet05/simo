# Design Tokens: SIMO Design System

Tài liệu này quy định tất cả các giá trị nguyên tử (Design Tokens) được áp dụng trên toàn bộ ứng dụng SIMO.

---

## 🎨 1. Hệ thống Màu sắc (Color Palette)

### 1.1 Màu cốt lõi (Core Colors)

| Tên Token | Mã Hex | Ý nghĩa & Vị trí sử dụng |
|-----------|--------|--------------------------|
| `AppColors.primary` | `#0F172A` (Slate 900) | Màu thương hiệu chính, thanh AppBar, nút bấm hành động nổi bật |
| `AppColors.secondary` | `#3B82F6` (Blue 500) | Nút tương tác phụ, biểu đồ thanh, liên kết |
| `AppColors.background` | `#F8FAFC` (Slate 50) | Nền toàn màn hình (Light Mode) |
| `AppColors.surface` | `#FFFFFF` | Bề mặt thẻ Card, Modal BottomSheet, Dialog |
| `AppColors.textPrimary` | `#1E293B` (Slate 800) | Chữ tiêu đề chính, số tiền giao dịch, nhãn quan trọng |
| `AppColors.textSecondary` | `#64748B` (Slate 500) | Chữ mô tả phụ, ngày giờ, chú thích |

---

### 1.2 Màu ngữ nghĩa (Semantic Colors)

| Tên Token | Màu chính (Main) | Màu nền nhạt (Soft Bg) | Ngữ cảnh sử dụng |
|-----------|------------------|------------------------|------------------|
| **Income (Thu nhập / Nạp tiền)** | `AppColors.income` (`#10B981`) | `AppColors.incomeBg` (`#D1FAE5`) | Khoản thu nhập, nạp tiền vào hũ, số dư tăng, badge Hoàn thành |
| **Expense (Chi tiêu / Rút tiền)** | `AppColors.expense` (`#EF4444`) | `AppColors.expenseBg` (`#FEE2E2`) | Khoản chi tiêu, rút tiền, cảnh báo lỗi, nút xóa dữ liệu |
| **Warning (Cảnh báo)** | `AppColors.warning` (`#F59E0B`) | `AppColors.warningBg` (`#FEF3C7`) | Gần chạm hạn mức ngân sách (>80%), sắp đến hạn trả nợ |
| **Info (Thông tin / Thống kê)** | `AppColors.info` (`#0EA5E9`) | `AppColors.infoBg` (`#E0F2FE`) | Gợi ý tài chính, mẹo tiết kiệm, tag thống kê |

---

### 1.3 Bảng màu danh mục (Category 10-Color Palette)

Dùng cho phân loại danh mục thu/chi, biểu đồ Donut chart, và biểu tượng danh mục:

```dart
static const List<Color> categoryPalette = [
  Color(0xFF6366F1), // Indigo
  Color(0xFF8B5CF6), // Violet
  Color(0xFFEC4899), // Pink
  Color(0xFFF43F5E), // Rose
  Color(0xFFF97316), // Orange
  Color(0xFFEAB308), // Yellow
  Color(0xFF84CC16), // Lime
  Color(0xFF22C55E), // Green
  Color(0xFF14B8A6), // Teal
  Color(0xFF06B6D4), // Cyan
];
```

---

### 1.4 Quy tắc làm mờ nền (Soft Tinting Rule)

Thay vì dùng màu đặc gây chói mắt, SIMO sử dụng cơ chế **Soft Tinting** cho container icon và background của thẻ:
- **Nền thẻ Hero / Overview**: `theme.colorScheme.primary.withValues(alpha: 0.05)`
- **Nền Icon Squircle**: `itemColor.withValues(alpha: 0.12 - 0.15)`
- **Đường viền thẻ Card**: `Colors.grey.withValues(alpha: 0.15 - 0.20)`

---

## 🔤 2. Quy chuẩn Chữ (Typography Scale)

| Cấp bậc (Role) | Kích thước (Size) | Độ đậm (Weight) | Màu sắc (Light / Dark) | Ví dụ ứng dụng |
|----------------|-------------------|-----------------|------------------------|----------------|
| **Display / Hero Metric** | 24 - 28sp | Bold (`FontWeight.bold`) | `textPrimary` / Primary Color | Số dư tổng, Tổng tiền tiết kiệm |
| **AppBar Title** | 18 - 20sp | Bold (`FontWeight.bold`) | AppBar Foreground | Tiêu đề trang |
| **Section Header** | 16sp | Bold (`FontWeight.bold`) | `textPrimary` | "Truy cập nhanh", "Lịch sử nạp / rút" |
| **Card Title / Item Name** | 15 - 16sp | Semi-Bold (`FontWeight.w600`) | `textPrimary` | Tên mục tiêu, Tên danh mục, Tên người nợ |
| **Body / Content** | 13 - 14sp | Regular (`FontWeight.normal`) | `textPrimary` | Nội dung ghi chú, chi tiết giao dịch |
| **Caption / Subtitle** | 11 - 12sp | Medium (`FontWeight.w500`) | `textSecondary` / Grey | Ngày giờ, Hạn chót, Tỷ lệ phần trăm |
| **Badge Label** | 10 - 11sp | Bold (`FontWeight.bold`) | Semantic Color | "Đã hoàn thành", "Cho vay", "Đi vay" |

---

## 📐 3. Hệ thống Khoảng cách & Lưới (Spacing Grid 8dp)

| Token | Giá trị (dp) | Mục đích sử dụng |
|-------|--------------|------------------|
| `space-xxs` | 4dp | Khoảng cách siêu nhỏ giữa icon và nhãn badge |
| `space-xs` | 8dp | Khoảng cách giữa các chip lọc, giữa các dòng trong thẻ |
| `space-sm` | 12dp | Khoảng cách giữa icon và tiêu đề, khoảng cách giữa các thẻ danh sách |
| `space-md` | 16dp | **Padding chuẩn của màn hình**, padding trong của thẻ Card tiêu chuẩn |
| `space-lg` | 20dp | Padding trong của thẻ Hero Overview, padding đầu modal BottomSheet |
| `space-xl` | 24dp | Khoảng cách giữa các phân đoạn (Sections) lớn |
| `space-xxl`| 32dp | Khoảng cách trước các nút hành động chính ở chân trang |

---

## 🔘 4. Quy chuẩn Bo góc (Corner Radii)

```
┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐       ┌─────────────────┐
│     Radius sm   │       │    Radius md    │       │    Radius lg    │       │    Radius xl    │
│       8dp       │       │      12dp       │       │      16dp       │       │      20dp       │
│  Badges, Chips  │       │ Buttons, Inputs │       │   List Cards    │       │ Hero, Modals    │
└─────────────────┘       └─────────────────┘       └─────────────────┘       └─────────────────┘
```

- **`8dp` (Small)**: `ChoiceChip`, Status Badges, Container ngày tháng nhỏ.
- **`12dp` (Medium)**: Nút bấm `ElevatedButton`, ô nhập `TextFormField`, Container Icon Squircle.
- **`16dp` (Large)**: Thẻ danh sách giao dịch, thẻ mục tiêu, thẻ sổ nợ, AlertDialog.
- **`20dp` (Extra Large)**: Thẻ tổng quan Hero Overview, viền đỉnh Modal BottomSheet (`BorderRadius.vertical(top: Radius.circular(20))`).

---

## 🧊 5. Độ nổi & Đường viền (Elevation & Borders)

- **Elevation**: Luôn đặt `elevation: 0` trên AppBars, Cards và Buttons để duy trì phong cách **Flat UI** hiện đại.
- **Viền phân cách (Borders)**:
  - Thẻ thông thường: `side: BorderSide(color: Colors.grey.withValues(alpha: 0.15 - 0.20))`
  - Thẻ được kích hoạt hoặc hoàn thành: `side: BorderSide(color: Colors.green.withValues(alpha: 0.3), width: 1.5)`
