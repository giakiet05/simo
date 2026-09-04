# Contract: FuzzySearchService

## Purpose
Cung cấp dịch vụ chuẩn hóa tiếng Việt, nhận diện số tiền viết tắt và thực hiện tìm kiếm mờ trên tập danh sách giao dịch theo các trường: Ghi chú, Tên danh mục, Tên ví, và Số tiền.

## Public Interface

```dart
abstract class IFuzzySearchService {
  /// Chuẩn hóa chuỗi tiếng Việt thành chuỗi chữ thường không dấu
  /// Ví dụ: "Ăn trưa Bún Bò" -> "an trua bun bo"
  String normalizeVietnamese(String input);

  /// Kiểm tra và bóc tách số tiền viết tắt
  /// Ví dụ:
  /// - "50k" -> 50000.0
  /// - "1.5tr" / "1.5m" -> 1500000.0
  /// - "200nghin" -> 200000.0
  /// - "abc" -> null
  double? tryParseShorthandAmount(String query);

  /// Lọc và tính điểm các giao dịch khớp với từ khóa tìm kiếm
  /// [transactions]: Danh sách giao dịch đã qua bộ lọc cơ sở
  /// [query]: Từ khóa tìm kiếm người dùng nhập
  /// [categoryMap]: Map categoryId -> Category (để tìm theo tên danh mục)
  /// [walletMap]: Map walletId -> Wallet (để tìm theo tên ví)
  List<Transaction> search({
    required List<Transaction> transactions,
    required String query,
    required Map<String, Category> categoryMap,
    required Map<String, Wallet> walletMap,
  });
}
```

## Behavior Contract
1. Khi `query.trim().isEmpty`: Trả về nguyên trạng danh sách `transactions` ban đầu.
2. Khi `query` là số tiền hoặc viết tắt số tiền ("50k"):
   - Tìm chính xác các giao dịch có `tx.amount == parsedAmount`.
3. Khi `query` là văn bản:
   - Chuẩn hóa `query` và các trường `note`, `category.name`, `wallet.name`.
   - Tìm kiếm theo substring match hoặc fuzzy similarity.
   - Thứ tự trả về: Giữ nguyên thứ tự thời gian giảm dần (hoặc giao dịch mới nhất lên đầu).
