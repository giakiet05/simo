import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../utils/localization.dart';

class DashboardNetWorthCard extends StatelessWidget {
  final double netWorth;
  final String currency;
  final bool isHidden;
  final VoidCallback onTogglePrivacy;
  final VoidCallback onTransferTap;
  final VoidCallback onViewAllWalletsTap;
  final dynamic l10n;

  const DashboardNetWorthCard({
    super.key,
    required this.netWorth,
    required this.currency,
    required this.isHidden,
    required this.onTogglePrivacy,
    required this.onTransferTap,
    required this.onViewAllWalletsTap,
    required this.l10n,
  });

  String _formatCurrency(double amount) {
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

    final primaryColor = isDark
        ? const Color(0xFF065F46)
        : const Color(0xFF059669);
    final secondaryColor = isDark
        ? const Color(0xFF047857)
        : const Color(0xFF10B981);

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
            color: secondaryColor.withValues(alpha: 0.3),
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

          // Net Worth Display
          Text(
            isHidden ? '••••••••' : _formatCurrency(netWorth),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 18),

          // Quick Action Buttons
          Row(
            children: [
              Expanded(
                child: Material(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onTransferTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.swap_horiz_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n is AppLocalizations
                                ? l10n.transferShort
                                : (l10n.locale == 'vi' ? 'Chuyển tiền' : 'Transfer'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Material(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    onTap: onViewAllWalletsTap,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: Colors.white,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            l10n is AppLocalizations
                                ? l10n.allWallets
                                : (l10n.locale == 'vi' ? 'Ví tiền' : 'Wallets'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
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
