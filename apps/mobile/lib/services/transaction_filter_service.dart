import '../models/category.dart';
import '../models/transaction.dart';
import '../models/transaction_filter_criteria.dart';
import '../models/wallet.dart';
import 'fuzzy_search_service.dart';

class TransactionFilterService {
  final FuzzySearchService _fuzzySearchService;

  TransactionFilterService({FuzzySearchService? fuzzySearchService})
      : _fuzzySearchService = fuzzySearchService ?? FuzzySearchService();

  /// Kiểm tra xem một giao dịch có thỏa mãn các tiêu chí lọc cơ sở (không bao gồm searchQuery)
  bool matchesCriteria({
    required Transaction transaction,
    required TransactionFilterCriteria criteria,
  }) {
    // 1. Lọc theo Ví (đa ví)
    if (criteria.selectedWalletIds.isNotEmpty) {
      if (transaction.walletId == null ||
          !criteria.selectedWalletIds.contains(transaction.walletId)) {
        return false;
      }
    }

    // 2. Lọc theo Danh mục (đa danh mục)
    if (criteria.selectedCategoryIds.isNotEmpty) {
      if (transaction.categoryId == null ||
          !criteria.selectedCategoryIds.contains(transaction.categoryId)) {
        return false;
      }
    }

    // 3. Lọc theo Loại (income / expense)
    if (criteria.type != null && criteria.type!.isNotEmpty) {
      if (transaction.type != criteria.type) {
        return false;
      }
    }

    // 4. Lọc theo Số tiền (minAmount, maxAmount)
    if (criteria.minAmount != null && transaction.amount < criteria.minAmount!) {
      return false;
    }
    if (criteria.maxAmount != null && transaction.amount > criteria.maxAmount!) {
      return false;
    }

    // 5. Lọc theo Thời gian
    final txDate = transaction.transactionDate;
    final now = DateTime.now();

    switch (criteria.timeMode) {
      case TimeFilterMode.all:
        break;
      case TimeFilterMode.today:
        if (txDate.year != now.year || txDate.month != now.month || txDate.day != now.day) {
          return false;
        }
        break;
      case TimeFilterMode.thisWeek:
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        if (txDate.isBefore(startOfWeek) || !txDate.isBefore(endOfWeek)) {
          return false;
        }
        break;
      case TimeFilterMode.thisMonth:
        if (txDate.year != now.year || txDate.month != now.month) {
          return false;
        }
        break;
      case TimeFilterMode.lastMonth:
        final lastMonth = DateTime(now.year, now.month - 1);
        if (txDate.year != lastMonth.year || txDate.month != lastMonth.month) {
          return false;
        }
        break;
      case TimeFilterMode.thisYear:
        if (txDate.year != now.year) {
          return false;
        }
        break;
      case TimeFilterMode.customMonth:
        if (criteria.customMonth != null) {
          if (txDate.year != criteria.customMonth!.year ||
              txDate.month != criteria.customMonth!.month) {
            return false;
          }
        }
        break;
      case TimeFilterMode.customDateRange:
        if (criteria.startDate != null) {
          final startOfDay = DateTime(
            criteria.startDate!.year,
            criteria.startDate!.month,
            criteria.startDate!.day,
          );
          if (txDate.isBefore(startOfDay)) {
            return false;
          }
        }
        if (criteria.endDate != null) {
          final endOfDay = DateTime(
            criteria.endDate!.year,
            criteria.endDate!.month,
            criteria.endDate!.day,
            23,
            59,
            59,
            999,
          );
          if (txDate.isAfter(endOfDay)) {
            return false;
          }
        }
        break;
    }

    return true;
  }

  /// Áp dụng toàn bộ pipeline lọc:
  /// Dữ liệu thô -> Lọc tiêu chí (Ví, Danh mục, Loại, Ngày, Tiền) -> Tìm kiếm mờ -> Sắp xếp theo ngày giảm dần
  List<Transaction> applyFilter({
    required List<Transaction> allTransactions,
    required TransactionFilterCriteria criteria,
    required Map<String, Category> categoryMap,
    required Map<String, Wallet> walletMap,
  }) {
    // 1. Áp dụng các tiêu chí lọc cơ sở
    var filtered = allTransactions
        .where((tx) => matchesCriteria(transaction: tx, criteria: criteria))
        .toList();

    // 2. Áp dụng tìm kiếm mờ trên tập dữ liệu đã lọc
    if (criteria.searchQuery.trim().isNotEmpty) {
      filtered = _fuzzySearchService.search(
        transactions: filtered,
        query: criteria.searchQuery,
        categoryMap: categoryMap,
        walletMap: walletMap,
      );
    }

    // 3. Sắp xếp theo ngày giao dịch giảm dần, sau đó theo thời điểm tạo giảm dần
    filtered.sort((a, b) {
      final dateCmp = b.transactionDate.compareTo(a.transactionDate);
      if (dateCmp != 0) return dateCmp;
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
  }
}
