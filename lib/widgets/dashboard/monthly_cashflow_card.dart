import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/localization.dart';

class MonthlyCashflowCard extends StatelessWidget {
  final double netCashflow;
  final double income;
  final double expense;
  final String currency;
  final bool isHidden;
  final dynamic l10n;
  final VoidCallback? onTap;

  const MonthlyCashflowCard({
    super.key,
    required this.netCashflow,
    required this.income,
    required this.expense,
    required this.currency,
    this.isHidden = false,
    required this.l10n,
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

    final savingsRate = income > 0
        ? ((income - expense) / income * 100).clamp(-100.0, 100.0)
        : 0.0;

    return Material(
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
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
              // Header: Title + Status Badge + Chevron Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n is AppLocalizations
                            ? l10n.monthlyCashflow
                            : (l10n.locale == 'vi'
                                ? 'Dòng tiền tháng'
                                : 'Monthly Cash Flow'),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: flowColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              isSurplus
                                  ? Icons.trending_up_rounded
                                  : Icons.trending_down_rounded,
                              color: flowColor,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              isSurplus
                                  ? (l10n is AppLocalizations
                                      ? l10n.monthlySurplus
                                      : (l10n.locale == 'vi'
                                          ? 'Thặng dư'
                                          : 'Surplus'))
                                  : (l10n is AppLocalizations
                                      ? l10n.monthlyDeficit
                                      : (l10n.locale == 'vi'
                                          ? 'Thâm hụt'
                                          : 'Deficit')),
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
                ],
              ),
              const SizedBox(height: 10),

              // Net Cash Flow Value
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  isHidden
                      ? '••••••••'
                      : '${isSurplus ? '+' : ''}${_formatAmount(netCashflow)}',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: flowColor,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Savings Rate Progress Bar & Label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n is AppLocalizations
                        ? l10n.savingsRate
                        : (l10n.locale == 'vi' ? 'Tỷ lệ tích lũy' : 'Savings Rate'),
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    ),
                  ),
                  Text(
                    isHidden
                        ? '••%'
                        : '${savingsRate >= 0 ? '+' : ''}${savingsRate.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: flowColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: income > 0
                      ? (savingsRate > 0 ? savingsRate / 100 : 0.0)
                      : 0.0,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  valueColor: AlwaysStoppedAnimation<Color>(flowColor),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
