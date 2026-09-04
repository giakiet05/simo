# Quickstart Validation Guide: 014-advanced-filter-fuzzy-search

## Prerequisites
- Flutter SDK installed and environment healthy (`flutter doctor`).
- SQLite dev environment initialized with mock data (`flutter test test/unit/mock_data_generator_test.dart`).

## Validation Scenarios

### Scenario 1: Vietnamese Normalization & Fuzzy Search Unit Test
1. **Action**: Chạy unit test bộ chuẩn hóa tiếng Việt và thuật toán tìm kiếm mờ:
   ```bash
   flutter test test/unit/fuzzy_search_service_test.dart
   ```
2. **Expected Outcome**:
   - `normalizeVietnamese("Bún bò Huế")` trả về `"bun bo hue"`.
   - `tryParseShorthandAmount("50k")` trả về `50000.0`.
   - `tryParseShorthandAmount("1.5tr")` trả về `1500000.0`.
   - Tìm kiếm từ khóa "bun bo" tìm ra giao dịch có note "Bún bò Huế".
   - Tìm kiếm từ khóa "cafee" (sai 1 ký tự) tìm ra giao dịch có note "Cafe".

### Scenario 2: Multi-Wallet and Multi-Category Filtering Unit Test
1. **Action**: Chạy unit test pipeline lọc:
   ```bash
   flutter test test/unit/transaction_filter_service_test.dart
   ```
2. **Expected Outcome**:
   - Lọc với `selectedWalletIds = {'wallet-1', 'wallet-2'}` chỉ trả về giao dịch thuộc 2 ví này.
   - Lọc đồng thời `selectedCategoryIds = {'cat-food', 'cat-shopping'}` trả về giao dịch thuộc 2 danh mục này.
   - Nút đặt lại đưa tiêu chí lọc về `TransactionFilterCriteria.defaultState`.

### Scenario 3: UI Integration Test trên TransactionScreen
1. **Action**:
   ```bash
   flutter test test/widget_transaction_filter_test.dart
   ```
2. **Expected Outcome**:
   - Thanh Quick Filter Chips xuất hiện dưới AppBar với các chip: `[Ví: Tất cả ▾]`, `[Thời gian: Tất cả ▾]`, `[Loại: Tất cả ▾]`.
   - Bấm vào icon Tìm kiếm, gõ từ khóa "50k" -> Danh sách chỉ hiển thị giao dịch 50.000 đ được gom trong thẻ ngày.
   - Khi đang mở bộ lọc lọc riêng "Ví Tiền mặt", thanh tìm kiếm chỉ tìm các giao dịch thuộc "Ví Tiền mặt".
