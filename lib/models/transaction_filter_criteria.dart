import 'transaction.dart';

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
  }) {
    return TransactionFilterCriteria(
      searchQuery: searchQuery ?? this.searchQuery,
      selectedWalletIds: selectedWalletIds ?? this.selectedWalletIds,
      selectedCategoryIds: selectedCategoryIds ?? this.selectedCategoryIds,
      type: clearType ? null : (type ?? this.type),
      timeMode: timeMode ?? this.timeMode,
      customMonth: clearCustomMonth ? null : (customMonth ?? this.customMonth),
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
    );
  }

  bool get isDefault =>
      searchQuery.trim().isEmpty &&
      selectedWalletIds.isEmpty &&
      selectedCategoryIds.isEmpty &&
      type == null &&
      timeMode == TimeFilterMode.all &&
      customMonth == null &&
      startDate == null &&
      endDate == null &&
      minAmount == null &&
      maxAmount == null;

  /// Counts the active non-search filters for badges
  int get activeFilterCount {
    int count = 0;
    if (selectedWalletIds.isNotEmpty) count++;
    if (selectedCategoryIds.isNotEmpty) count++;
    if (type != null && type!.isNotEmpty) count++;
    if (timeMode != TimeFilterMode.all) count++;
    if (minAmount != null || maxAmount != null) count++;
    return count;
  }
}

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

class ShorthandAmountResult {
  final bool isAmountQuery;
  final double? parsedAmount;

  const ShorthandAmountResult({
    required this.isAmountQuery,
    this.parsedAmount,
  });
}
