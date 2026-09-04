# Phase 1 Data Model: 014-advanced-filter-fuzzy-search

## 1. Filter Criteria Model

```dart
enum TimeFilterMode {
  all,
  today,
  thisWeek,
  thisMonth,
  lastMonth,
  thisYear,
  customMonth,
  customDateRange,
}

class TransactionFilterCriteria {
  final String searchQuery;
  final Set<String> selectedWalletIds; // Empty = all wallets
  final Set<String> selectedCategoryIds; // Empty = all categories
  final String? type; // null = all, 'income', 'expense'
  final TimeFilterMode timeMode;
  final DateTime? customMonth; // For MonthYearPickerModal selection
  final DateTime? startDate; // For DateRange
  final DateTime? endDate; // For DateRange
  final double? minAmount;
  final double? maxAmount;

  const TransactionFilterCriteria({
    this.searchQuery = '',
    this.selectedWalletIds = const {},
    this.selectedCategoryIds = const {},
    this.type,
    this.timeMode = TimeFilterMode.all,
    this.customMonth,
    this.startDate,
    this.endDate,
    this.minAmount,
    this.maxAmount,
  });

  TransactionFilterCriteria copyWith({
    String? searchQuery,
    Set<String>? selectedWalletIds,
    Set<String>? selectedCategoryIds,
    String? type,
    bool clearType = false,
    TimeFilterMode? timeMode,
    DateTime? customMonth,
    bool clearCustomMonth = false,
    DateTime? startDate,
    bool clearStartDate = false,
    DateTime? endDate,
    bool clearEndDate = false,
    double? minAmount,
    bool clearMinAmount = false,
    double? maxAmount,
    bool clearMaxAmount = false,
  });

  bool get isDefault;
  int get activeFilterCount;
}
```

## 2. Fuzzy Search Match Result

```dart
class FuzzySearchResult {
  final Transaction transaction;
  final double score; // 0.0 to 1.0
  final Set<String> matchedFields; // 'note', 'category', 'wallet', 'amount'

  const FuzzySearchResult({
    required this.transaction,
    required this.score,
    required this.matchedFields,
  });
}
```

## 3. Shorthand Amount Parse Result

```dart
class ShorthandAmountResult {
  final bool isAmountQuery;
  final double? parsedAmount;

  const ShorthandAmountResult({
    required this.isAmountQuery,
    this.parsedAmount,
  });
}
```

## Validation Rules
1. `minAmount >= 0` and `maxAmount >= 0`. If both present, `minAmount <= maxAmount` must be enforced.
2. When `timeMode == TimeFilterMode.customDateRange`, `startDate` must be `<= endDate`.
3. When `searchQuery` is empty, fuzzy search is bypassed and all filtered transactions pass through.
