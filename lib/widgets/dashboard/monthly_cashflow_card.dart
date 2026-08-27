import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/localization.dart';

class MonthlyCashflowCard extends StatelessWidget {
  final double income;
  final double expense;
  final double netCashflow;
  final String currency;
  final dynamic l10n;

  const MonthlyCashflowCard({
    super.key,
    required this.income,
    required this.expense,
    required this.netCashflow,
    required this.currency,
    required this.l10n,
  });

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: currency == 'VND' ? '₫' : currency,
      decimalDigits: currency == 'VND' ? 0 : 2,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSurplus = netCashflow >= 0;

    final flowColor = isSurplus
        ? const Color(0xFF10B981)
        : const Color(0xFFEF4444);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n is AppLocalizations
                    ? l10n.monthlyCashflow
                    : (l10n.locale == 'vi' ? 'Dòng tiền tháng' : 'Monthly Cash Flow'),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: flowColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isSurplus ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      color: flowColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isSurplus
                          ? (l10n is AppLocalizations
                              ? l10n.monthlySurplus
                              : (l10n.locale == 'vi' ? 'Thặng dư' : 'Surplus'))
                          : (l10n is AppLocalizations
                              ? l10n.monthlyDeficit
                              : (l10n.locale == 'vi' ? 'Dòng tiền âm' : 'Deficit')),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: flowColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Net Cash Flow Value
          Text(
            '${isSurplus ? '+' : ''}${_formatAmount(netCashflow)}',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: flowColor,
            ),
          ),
          const SizedBox(height: 16),

          // Income vs Expense row
          Row(
            children: [
              // Income box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_downward_rounded,
                          color: Color(0xFF10B981),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n is AppLocalizations
                                  ? l10n.income
                                  : (l10n.locale == 'vi' ? 'Thu nhập' : 'Income'),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '+${_formatAmount(income)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Expense box
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.arrow_upward_rounded,
                          color: Color(0xFFEF4444),
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              l10n is AppLocalizations
                                  ? l10n.expense
                                  : (l10n.locale == 'vi' ? 'Chi tiêu' : 'Expense'),
                              style: TextStyle(
                                fontSize: 11,
                                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '-${_formatAmount(expense)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
