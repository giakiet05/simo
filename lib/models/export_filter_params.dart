enum ExportDateRange {
  thisMonth,
  lastMonth,
  thisYear,
  custom,
  allTime,
}

class ExportFilterParams {
  final ExportDateRange rangeType;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? typeFilter; // 'all', 'income', 'expense'
  final String currency;

  const ExportFilterParams({
    required this.rangeType,
    this.startDate,
    this.endDate,
    this.typeFilter = 'all',
    required this.currency,
  });

  /// Returns whether a given [date] falls within the configured filter range
  bool isDateInRange(DateTime date) {
    final now = DateTime.now();
    switch (rangeType) {
      case ExportDateRange.thisMonth:
        return date.year == now.year && date.month == now.month;
      case ExportDateRange.lastMonth:
        final lastMonthDate = DateTime(now.year, now.month - 1, 1);
        return date.year == lastMonthDate.year && date.month == lastMonthDate.month;
      case ExportDateRange.thisYear:
        return date.year == now.year;
      case ExportDateRange.custom:
        if (startDate != null && date.isBefore(DateTime(startDate!.year, startDate!.month, startDate!.day))) {
          return false;
        }
        if (endDate != null && date.isAfter(DateTime(endDate!.year, endDate!.month, endDate!.day, 23, 59, 59))) {
          return false;
        }
        return true;
      case ExportDateRange.allTime:
        return true;
    }
  }
}
