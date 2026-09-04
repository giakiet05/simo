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
  final dynamic l10n;

  const MiniWalletCarousel({
    super.key,
    required this.wallets,
    required this.currency,
    required this.isHidden,
    required this.onWalletTap,
    required this.onAddWalletTap,
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
    final symbol = currency == 'VND' ? '₫' : currency;
    final isNegative = amount < 0;
    final absFormatted = NumberFormat('#,###', 'en_US').format(amount.abs());
    return '${isNegative ? '-' : ''}$absFormatted $symbol';
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

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: wallets.length + 1,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          if (index == wallets.length) {
            // Add Wallet Button Card
            return Material(
              color: isDark
                  ? Colors.grey.shade900
                  : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onAddWalletTap,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 96,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.15),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline_rounded,
                        size: 15,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          l10n is AppLocalizations
                              ? l10n.addWallet
                              : (l10n.locale == 'vi' ? 'Thêm ví' : 'Add'),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.primary,
                          ),
                          overflow: TextOverflow.ellipsis,
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
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              onTap: () => onWalletTap(wallet),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: 145,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: color.withValues(alpha: 0.35),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: Icon + Name on same line
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          alignment: Alignment.center,
                          child: Icon(
                            _getWalletIcon(wallet.icon),
                            color: color,
                            size: 13,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            wallet.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (wallet.isDefault)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          )
                        else if (wallet.excludeFromTotal)
                          Icon(
                            Icons.visibility_off_outlined,
                            size: 11,
                            color: Colors.grey.shade500,
                          ),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Row 2: Balance
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        isHidden ? '••••••' : _formatAmount(wallet.currentBalance),
                        maxLines: 1,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: wallet.currentBalance < 0
                              ? Colors.red
                              : (isDark ? Colors.white : Colors.black87),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
