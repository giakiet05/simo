import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/wallet.dart';
import '../../utils/localization.dart';

class MiniWalletCarousel extends StatelessWidget {
  final List<Wallet> wallets;
  final String currency;
  final bool isHidden;
  final Function(Wallet wallet) onWalletTap;
  final VoidCallback onAddWalletTap;
  final VoidCallback onViewAllTap;
  final dynamic l10n;

  const MiniWalletCarousel({
    super.key,
    required this.wallets,
    required this.currency,
    required this.isHidden,
    required this.onWalletTap,
    required this.onAddWalletTap,
    required this.onViewAllTap,
    required this.l10n,
  });

  Color _parseColor(String colorStr) {
    try {
      final hex = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF10B981);
    }
  }

  String _formatAmount(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: currency == 'VND' ? '₫' : currency,
      decimalDigits: currency == 'VND' ? 0 : 2,
    );
    return formatter.format(amount);
  }

  IconData _getWalletIcon(String iconKey) {
    switch (iconKey) {
      case 'account_balance':
        return Icons.account_balance_rounded;
      case 'credit_card':
        return Icons.credit_card_rounded;
      case 'savings':
        return Icons.savings_rounded;
      case 'phone_android':
        return Icons.phone_android_rounded;
      case 'trending_up':
        return Icons.trending_up_rounded;
      case 'wallet':
      default:
        return Icons.account_balance_wallet_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n is AppLocalizations
                    ? l10n.allWallets
                    : (l10n.locale == 'vi' ? 'Tài khoản & Ví' : 'Accounts & Wallets'),
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: onViewAllTap,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  l10n is AppLocalizations
                      ? l10n.manageWallets
                      : (l10n.locale == 'vi' ? 'Quản lý' : 'Manage'),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Horizontal Carousel
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: wallets.length + 1,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              if (index == wallets.length) {
                // Add Wallet Button Card
                return Material(
                  color: isDark
                      ? Colors.grey.shade900
                      : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  child: InkWell(
                    onTap: onAddWalletTap,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 110,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.outline.withValues(alpha: 0.15),
                          style: BorderStyle.solid,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.add_circle_outline_rounded,
                            size: 26,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            l10n is AppLocalizations
                                ? l10n.addWallet
                                : (l10n.locale == 'vi' ? 'Thêm ví' : 'Add Wallet'),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              final wallet = wallets[index];
              final color = _parseColor(wallet.color);

              return Material(
                color: isDark
                    ? const Color(0xFF1E293B)
                    : Colors.white,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  onTap: () => onWalletTap(wallet),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    width: 155,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: color.withValues(alpha: 0.35),
                        width: 1.2,
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _getWalletIcon(wallet.icon),
                                color: color,
                                size: 18,
                              ),
                            ),
                            if (wallet.isDefault)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  l10n is AppLocalizations
                                      ? l10n.defaultWalletBadge
                                      : 'Mặc định',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                  ),
                                ),
                              )
                            else if (wallet.excludeFromTotal)
                              Icon(
                                Icons.visibility_off_outlined,
                                size: 14,
                                color: Colors.grey.shade500,
                              ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              wallet.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              isHidden ? '••••••' : _formatAmount(wallet.currentBalance),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: wallet.currentBalance < 0
                                    ? Colors.red
                                    : (isDark ? Colors.white : Colors.black87),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
