import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/localization.dart';

class DashboardNetWorthCard extends StatelessWidget {
  final double netWorth;
  final String currency;
  final bool isHidden;
  final VoidCallback onTogglePrivacy;
  final VoidCallback? onTap;
  final dynamic l10n;

  const DashboardNetWorthCard({
    super.key,
    required this.netWorth,
    required this.currency,
    required this.isHidden,
    required this.onTogglePrivacy,
    this.onTap,
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

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, secondaryColor],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: secondaryColor.withValues(alpha: 0.22),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header: Title + Chevron link to all wallets + Privacy Eye Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance_wallet_rounded,
                        color: Colors.white70,
                        size: 15,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n is AppLocalizations
                            ? l10n.totalNetWorth
                            : (l10n.locale == 'vi' ? 'TỔNG TÀI SẢN' : 'TOTAL NET WORTH'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white60,
                        size: 16,
                      ),
                    ],
                  ),
                  InkResponse(
                    onTap: onTogglePrivacy,
                    radius: 16,
                    child: Padding(
                      padding: const EdgeInsets.all(2.0),
                      child: Icon(
                        isHidden ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                        color: Colors.white70,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),

              // Net Worth Display with FittedBox
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  isHidden ? '••••••••' : _formatCurrency(netWorth),
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
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
