import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/localization.dart';

class DashboardNetWorthCard extends StatelessWidget {
  final double netWorth;
  final String currency;
  final bool isHidden;
  final VoidCallback onTogglePrivacy;
  final dynamic l10n;

  const DashboardNetWorthCard({
    super.key,
    required this.netWorth,
    required this.currency,
    required this.isHidden,
    required this.onTogglePrivacy,
    required this.l10n,
  });

  String _formatCurrency(double amount) {
    final symbol = currency == 'VND' ? '₫' : currency;
    final isNegative = amount < 0;
    final absFormatted = NumberFormat('#,###', 'en_US').format(amount.abs());
    return '${isNegative ? '-' : ''}$absFormatted $symbol';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isNegative = netWorth < 0;

    // Dynamic gradient: Green for >= 0, Red for < 0
    final primaryColor = isNegative
        ? (isDark ? const Color(0xFF991B1B) : const Color(0xFFDC2626))
        : (isDark ? const Color(0xFF065F46) : const Color(0xFF059669));
    final secondaryColor = isNegative
        ? (isDark ? const Color(0xFFB91C1C) : const Color(0xFFEF4444))
        : (isDark ? const Color(0xFF047857) : const Color(0xFF10B981));

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: secondaryColor.withValues(alpha: 0.28),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Title + Privacy Eye Toggle
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.account_balance_wallet_rounded,
                    color: Colors.white70,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    l10n is AppLocalizations
                        ? l10n.totalNetWorth
                        : (l10n.locale == 'vi' ? 'TỔNG TÀI SẢN' : 'TOTAL NET WORTH'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(
                  isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                  color: Colors.white70,
                  size: 20,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                tooltip: isHidden
                    ? (l10n.locale == 'vi' ? 'Hiện số dư' : 'Show Balance')
                    : (l10n.locale == 'vi' ? 'Ẩn số dư' : 'Hide Balance'),
                onPressed: onTogglePrivacy,
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Net Worth Display with FittedBox
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              isHidden ? '••••••••' : _formatCurrency(netWorth),
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
