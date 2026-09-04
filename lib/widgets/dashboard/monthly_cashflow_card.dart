import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MonthlyCashflowCard extends StatelessWidget {
  final double netCashflow;
  final String currency;
  final bool isHidden;
  final dynamic l10n;
  final int selectedMonth;
  final int selectedYear;
  final VoidCallback? onPreviousMonth;
  final VoidCallback? onNextMonth;
  final VoidCallback onMonthPickerTap;
  final VoidCallback? onTap;

  const MonthlyCashflowCard({
    super.key,
    required this.netCashflow,
    required this.currency,
    this.isHidden = false,
    required this.l10n,
    required this.selectedMonth,
    required this.selectedYear,
    this.onPreviousMonth,
    this.onNextMonth,
    required this.onMonthPickerTap,
    this.onTap,
  });

  String _formatAmount(double amount) {
    final symbol = currency == 'VND' ? '₫' : currency;
    final isNegative = amount < 0;
    final absFormatted = NumberFormat('#,###', 'en_US').format(amount.abs());
    return '${isNegative ? '-' : ''}$absFormatted $symbol';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSurplus = netCashflow >= 0;

    final flowColor = isSurplus
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title + Month Navigator Capsule
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.payments_outlined,
                        size: 15,
                        color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.locale == 'vi' ? 'Dòng tiền' : 'Cash Flow',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),

                  // Month Navigator Pill
                  GestureDetector(
                    onTap: () {}, // Prevent taps inside month navigator from bubbling to the parent Card
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: isDark ? 0.35 : 0.45),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left_rounded, size: 18),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 26, minHeight: 26),
                          onPressed: onPreviousMonth,
                          tooltip: l10n.locale == 'vi'
                              ? 'Tháng trước'
                              : 'Previous month',
                        ),
                        InkWell(
                          onTap: onMonthPickerTap,
                          borderRadius: BorderRadius.circular(10),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  '$selectedMonth/$selectedYear',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                                const SizedBox(width: 2),
                                Icon(
                                  Icons.arrow_drop_down_rounded,
                                  size: 16,
                                  color: theme.colorScheme.primary,
                                ),
                              ],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right_rounded, size: 18),
                          padding: EdgeInsets.zero,
                          constraints:
                              const BoxConstraints(minWidth: 26, minHeight: 26),
                          onPressed: onNextMonth,
                          tooltip: l10n.locale == 'vi'
                              ? 'Tháng sau'
                              : 'Next month',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              ),
              const SizedBox(height: 4),

              // Net Cash Flow Value
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  isHidden
                      ? '••••••••'
                      : '${isSurplus ? '+' : ''}${_formatAmount(netCashflow)}',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: flowColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
