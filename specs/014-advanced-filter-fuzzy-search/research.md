# Phase 0 Research: 014-advanced-filter-fuzzy-search

## Research Item 1: Vietnamese Accent-Insensitive Normalization & Fuzzy Search Algorithm

### Decision
Xây dựng một module `FuzzySearchService` thuần Dart, offline 100% không phụ thuộc thư viện bên ngoài.
Quy trình tìm kiếm 3 tầng:
1. **Vietnamese Normalization (Tiếng Việt không dấu)**: Chuyển đổi toàn bộ nguyên âm có dấu (`á, à, ả, ã, ạ, â, ă...`) thành ký tự gốc không dấu (`a`), chuyển `đ/Đ` thành `d`, chuyển về chữ thường và cắt tỉa khoảng trắng.
2. **Shorthand Money Parser (Bóc tách số tiền viết tắt)**:
   - Sử dụng Regex bắt các mẫu: `50k` (50.000), `1.5tr` / `1.5m` (1.500.000), `200nghin` (200.000).
   - Nếu từ khóa khớp với mẫu số tiền: tìm các giao dịch có `amount == parsedAmount` (hoặc chênh lệch 0).
3. **Fuzzy Scoring Engine (Chấm điểm độ khớp)**:
   - **Exact/Contains match (Score = 1.0)**: Normalized query là chuỗi con của note / category name / wallet name.
   - **Acronym match (Score = 0.8)**: Ký tự đầu của các từ (ví dụ "cf" khớp "Cà phê", "an" khớp "Ăn uống").
   - **Subsequence / Fuzzy match (Score >= 0.5)**: Cho phép gõ thiếu/thừa 1-2 ký tự (Levenshtein distance <= 1 cho từ ngắn hoặc fuzzy subsequence matching).
   - Giao dịch có điểm score > 0 được coi là khớp. Thứ tự trả về vẫn được giữ theo ngày giao dịch giảm dần (nhất quán với tiêu chí Clarification 1).

### Rationale
- Chạy cực kỳ nhanh (< 2ms trên 1.000 giao dịch).
- Không làm tăng kích thước app, bảo đảm hoạt động offline an toàn.
- Xử lý mượt mà thói quen gõ tiếng Việt không dấu và viết tắt của người dùng.

### Alternatives Considered
- Thư viện `fuzzy`: Thư viện pub.dev này tính điểm tốt nhưng không hỗ trợ chuẩn hóa dấu tiếng Việt tích hợp sẵn và chậm hơn khi tìm kiếm đa trường.
- SQLite FTS5 (Full-Text Search): Quá phức tạp khi cần search đa bảng (giao dịch, ví, danh mục) và cần re-index liên tục.

---

## Research Item 2: Filter Architecture & State Pipeline

### Decision
Tách biệt trạng thái bộ lọc thành một immutable model `TransactionFilterState`:
```dart
class TransactionFilterState {
  final String searchQuery;
  final Set<String> selectedWalletIds; // rỗng = tất cả ví
  final Set<String> selectedCategoryIds; // rỗng = tất cả danh mục
  final String? type; // null = all, 'income', 'expense'
  final TimeFilterType timeFilter; // all, today, this_week, this_month, last_month, this_year, custom_month, custom_range
  final DateTime? customMonth; // Dùng với MonthYearPickerModal
  final DateTime? startDate;
  final DateTime? endDate;
  final double? minAmount;
  final double? maxAmount;
}
```

Pipeline lọc tuần tự rõ ràng:
1. **Lọc cơ sở (Base Filter)**:
   - Lọc Ví: `selectedWalletIds.isEmpty || selectedWalletIds.contains(tx.walletId)`
   - Lọc Danh mục: `selectedCategoryIds.isEmpty || selectedCategoryIds.contains(tx.categoryId)`
   - Lọc Loại: `type == null || tx.type == type`
   - Lọc Thời gian: so sánh `tx.transactionDate`
   - Lọc Khoảng tiền: `amount >= min && amount <= max`
2. **Tìm kiếm mờ (Fuzzy Search)**:
   - Chỉ chạy trên tập giao dịch đã vượt qua Base Filter.
3. **Phân trang & Gom nhóm (Pagination & Day Grouping)**:
   - Sắp xếp theo ngày giảm dần.
   - Cắt trang theo `currentPage * limit`.
   - Gom vào `_DayGroup` để hiển thị Day Cards.

### Rationale
- Đáp ứng chính xác yêu cầu của người dùng: "Tìm kiếm trên data đã lọc".
- Code được tách lớp rõ ràng, dễ viết unit test độc lập cho từng khâu.

---

## Research Item 3: Quick Filter Chips & Modal UX

### Decision
1. **Thanh Quick Filter Chips**:
   - Vị trí: Đặt ngay bên dưới AppBar (khi không tìm kiếm hoặc cả khi đang tìm kiếm).
   - Danh sách chips:
     - `[Ví: Tất cả ▾]` (hoặc hiển thị tên ví đang chọn, ví dụ `[Ví: Tiền mặt ▾]`)
     - `[Thời gian: Tháng này ▾]`
     - `[Loại: Tất cả ▾]`
     - `[Bộ lọc (badge) ⚙]`: Mở Modal đầy đủ.
   - Khi chạm vào chip Ví / Thời gian / Loại: Mở PopupMenuButton hoặc BottomSheet nhỏ để chọn nhanh 1 chạm.
2. **Modal Bộ Lọc Nâng Cao (Full Filter Sheet)**:
   - Giữ lại `_showFilterSheet` nhưng thiết kế lại hiện đại:
     - Section 1: Ví (Lưới FilterChip đa chọn kèm nút "Chọn tất cả").
     - Section 2: Loại giao dịch (ChoiceChip: Tất cả / Thu / Chi).
     - Section 3: Danh mục (Lưới FilterChip kèm icon).
     - Section 4: Thời gian (ChoiceChips các mốc nhanh + nút chọn Tháng/Năm mở `MonthYearPickerModal` + nút chọn Khoảng ngày).
     - Section 5: Khoảng tiền (2 ô nhập số Min - Max có định dạng tiền tệ).
     - Thanh bottom cố định: Nút "Đặt lại" (outline) và Nút "Áp dụng" (primary, có đếm số kết quả).

### Rationale
- Mang lại trải nghiệm mượt mà, chuyên nghiệp chuẩn Material 3.
- Tiết kiệm thao tác tối đa cho các nhu cầu lọc hàng ngày.
