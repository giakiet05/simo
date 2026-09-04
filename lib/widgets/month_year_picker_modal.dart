import 'package:flutter/material.dart';
import '../models/transaction.dart';

/// Helper model to track allowed month-year boundaries based on data
class MonthRange {
  final int startYear;
  final int startMonth;
  final int endYear;
  final int endMonth;

  const MonthRange({
    required this.startYear,
    required this.startMonth,
    required this.endYear,
    required this.endMonth,
  });

  /// Derives the range from transactions: earliest transaction to current month
  factory MonthRange.fromTransactions(List<Transaction> transactions) {
    final now = DateTime.now();
    final endYear = now.year;
    final endMonth = now.month;

    if (transactions.isEmpty) {
      return MonthRange(
        startYear: endYear,
        startMonth: endMonth,
        endYear: endYear,
        endMonth: endMonth,
      );
    }

    DateTime earliest = transactions.first.transactionDate;
    for (final tx in transactions) {
      if (tx.transactionDate.isBefore(earliest)) {
        earliest = tx.transactionDate;
      }
    }

    int startYear = earliest.year;
    int startMonth = earliest.month;

    // Guard against future dates
    if (startYear > endYear || (startYear == endYear && startMonth > endMonth)) {
      startYear = endYear;
      startMonth = endMonth;
    }

    return MonthRange(
      startYear: startYear,
      startMonth: startMonth,
      endYear: endYear,
      endMonth: endMonth,
    );
  }

  bool canGoPrevious(int year, int month) {
    return (year > startYear) || (year == startYear && month > startMonth);
  }

  bool canGoNext(int year, int month) {
    return (year < endYear) || (year == endYear && month < endMonth);
  }

  ({int year, int month}) previous(int year, int month) {
    if (!canGoPrevious(year, month)) {
      return (year: year, month: month);
    }
    if (month > 1) {
      return (year: year, month: month - 1);
    } else {
      return (year: year - 1, month: 12);
    }
  }

  ({int year, int month}) next(int year, int month) {
    if (!canGoNext(year, month)) {
      return (year: year, month: month);
    }
    if (month < 12) {
      return (year: year, month: month + 1);
    } else {
      return (year: year + 1, month: 1);
    }
  }

  ({int year, int month}) clamp(int year, int month) {
    if (year > endYear || (year == endYear && month > endMonth)) {
      return (year: endYear, month: endMonth);
    }
    if (year < startYear || (year == startYear && month < startMonth)) {
      return (year: startYear, month: startMonth);
    }
    return (year: year, month: month);
  }
}

/// Displays the standardized Month/Year picker bottom sheet
void showMonthYearPickerModal(
  BuildContext context,
  dynamic l10n, {
  required int currentYear,
  required int currentMonth,
  required int startYear,
  required int startMonth,
  required int endYear,
  required int endMonth,
  required void Function(int year, int month) onSelected,
  bool showAllTimeOption = false,
  VoidCallback? onSelectAllTime,
}) {
  int tempYear = currentYear.clamp(startYear, endYear);

  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final allowedMonths = <int>[];
          for (int m = 1; m <= 12; m++) {
            final isAfterStart = (tempYear > startYear) ||
                (tempYear == startYear && m >= startMonth);
            final isBeforeEnd =
                (tempYear < endYear) || (tempYear == endYear && m <= endMonth);
            if (isAfterStart && isBeforeEnd) {
              allowedMonths.add(m);
            }
          }

          final theme = Theme.of(context);
          final isDark = theme.brightness == Brightness.dark;

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showAllTimeOption && onSelectAllTime != null) ...[
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () {
                          onSelectAllTime();
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.all_inclusive_rounded, size: 18),
                        label: Text(
                          l10n.allTime ?? 'Tất cả',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],

                  // Year Navigation Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: tempYear > startYear
                            ? () => setModalState(() => tempYear--)
                            : null,
                      ),
                      Text(
                        tempYear.toString(),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: tempYear < endYear
                            ? () => setModalState(() => tempYear++)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Month Grid
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 2.2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: allowedMonths.length,
                    itemBuilder: (context, index) {
                      final month = allowedMonths[index];
                      final isSelected =
                          month == currentMonth && tempYear == currentYear;
                      return InkWell(
                        onTap: () {
                          onSelected(tempYear, month);
                          Navigator.pop(context);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : (isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            l10n.locale == 'vi'
                                ? 'Tháng $month'
                                : 'Month $month',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : theme.textTheme.bodyMedium?.color,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// A standard reusable Month Navigation Bar for headers/toolbars
class MonthNavigationBar extends StatelessWidget {
  final int selectedYear;
  final int selectedMonth;
  final bool canGoPrevious;
  final bool canGoNext;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onMonthTap;
  final dynamic l10n;
  final String? customLabel;

  const MonthNavigationBar({
    super.key,
    required this.selectedYear,
    required this.selectedMonth,
    required this.canGoPrevious,
    required this.canGoNext,
    required this.onPrevious,
    required this.onNext,
    required this.onMonthTap,
    required this.l10n,
    this.customLabel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayText = customLabel ?? '$selectedMonth/$selectedYear';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {}, // Prevent taps from bubbling up to any ancestor
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left_rounded),
              onPressed: canGoPrevious ? onPrevious : null,
              tooltip: l10n.locale == 'vi' ? 'Tháng trước' : 'Previous month',
            ),
            InkWell(
              onTap: onMonthTap,
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayText,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.arrow_drop_down_rounded,
                      size: 20,
                      color: theme.colorScheme.primary,
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right_rounded),
              onPressed: canGoNext ? onNext : null,
              tooltip: l10n.locale == 'vi' ? 'Tháng sau' : 'Next month',
            ),
          ],
        ),
      ),
    );
  }
}
