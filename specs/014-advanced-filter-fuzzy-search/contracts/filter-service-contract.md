# Contract: TransactionFilterService

## Purpose
Thực thi pipeline lọc đa tiêu chí trên tập dữ liệu giao dịch dựa trên đối tượng `TransactionFilterCriteria`.

## Public Interface

```dart
abstract class ITransactionFilterService {
  /// Áp dụng toàn bộ tiêu chí lọc lên danh sách giao dịch
  List<Transaction> applyFilter({
    required List<Transaction> allTransactions,
    required TransactionFilterCriteria criteria,
    required Map<String, Category> categoryMap,
    required Map<String, Wallet> walletMap,
  });

  /// Kiểm tra xem một giao dịch có thỏa mãn các tiêu chí lọc cơ sở (không bao gồm search text)
  bool matchesCriteria({
    required Transaction transaction,
    required TransactionFilterCriteria criteria,
  });
}
```

## Filter Pipeline Contract
Thứ tự thực thi:
1. Lọc theo Ví (`selectedWalletIds`): Nếu rỗng thì nhận tất cả, nếu có thì `selectedWalletIds.contains(tx.walletId)`.
2. Lọc theo Danh mục (`selectedCategoryIds`): Nếu rỗng thì nhận tất cả, nếu có thì `selectedCategoryIds.contains(tx.categoryId)`.
3. Lọc theo Loại (`type`): Nếu `null` thì nhận cả thu & chi.
4. Lọc theo Thời gian (`timeMode`, `customMonth`, `startDate`, `endDate`).
5. Lọc theo Số tiền (`minAmount`, `maxAmount`).
6. Tìm kiếm mờ (`searchQuery`): Thực thi `FuzzySearchService.search` trên tập dữ liệu kết quả từ bước 5.
