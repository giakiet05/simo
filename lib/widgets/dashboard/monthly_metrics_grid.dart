import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/localization.dart';

class MonthlyMetricsGrid extends StatelessWidget {
  final double income;
  final double expense;
  final double totalLent;
  final double totalBorrowed;
  final String currency;
  final bool isHidden;
  final dynamic l10n;
  final VoidCallback? onIncomeTap;
  final VoidCallback? onExpenseTap;
  final VoidCallback? onLentTap;
  final VoidCallback? onBorrowedTap;

  const MonthlyMetricsGrid({
    super.key,
    required this.income,
    required this.expense,
    required this.totalLent,
    required this.totalBorrowed,
    required this.currency,
    required this.isHidden,
    required this.l10n,
    this.onIncomeTap,
    this.onExpenseTap,
    this.onLentTap,
    this.onBorrowedTap,
  });

  String _formatAmount(double amount) {
    final symbol = currency == 'VND' ? '₫' : currency;
    final absFormatted = NumberFormat('#,###', 'en_US').format(amount.abs());
    return '$absFormatted $symbol';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final incomeLabel = l10n is AppLocalizations
        ? l10n.income
        : (l10n.locale == 'vi' ? 'Thu nhập' : 'Income');
    final expenseLabel = l10n is AppLocalizations
        ? l10n.expense
        : (l10n.locale == 'vi' ? 'Chi tiêu' : 'Expense');
    final lentLabel = l10n.locale == 'vi' ? 'Cho vay' : 'Lend';
    final borrowedLabel = l10n.locale == 'vi' ? 'Nợ' : 'Debt';

    return Column(
      children: [
        // Row 1: Income & Expense
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context: context,
                theme: theme,
                isDark: isDark,
                title: incomeLabel,
                amount: income,
                prefix: '+',
                icon: Icons.arrow_downward_rounded,
                accentColor: const Color(0xFF10B981),
                onTap: onIncomeTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                context: context,
                theme: theme,
                isDark: isDark,
                title: expenseLabel,
                amount: expense,
                prefix: '-',
                icon: Icons.arrow_upward_rounded,
                accentColor: const Color(0xFFEF4444),
                onTap: onExpenseTap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Row 2: Nợ (Left) & Cho vay (Right)
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                context: context,
                theme: theme,
                isDark: isDark,
                title: borrowedLabel,
                amount: totalBorrowed,
                prefix: '',
                icon: Icons.call_received_rounded,
                accentColor: const Color(0xFF8B5CF6),
                onTap: onBorrowedTap,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricCard(
                context: context,
                theme: theme,
                isDark: isDark,
                title: lentLabel,
                amount: totalLent,
                prefix: '',
                icon: Icons.call_made_rounded,
                accentColor: const Color(0xFFF59E0B),
                onTap: onLentTap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required ThemeData theme,
    required bool isDark,
    required String title,
    required double amount,
    required String prefix,
    required IconData icon,
    required Color accentColor,
    required VoidCallback? onTap,
  }) {
    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Row 1: Icon + Title on the same line
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Icon(icon, color: accentColor, size: 14),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Row 2: Value
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  isHidden
                      ? '••••••'
                      : (amount == 0 ? _formatAmount(0) : '$prefix${_formatAmount(amount)}'),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: amount == 0
                        ? (isDark ? Colors.white70 : Colors.black54)
                        : accentColor,
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
