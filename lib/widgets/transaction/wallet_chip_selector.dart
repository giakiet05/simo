import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/wallet.dart';
import '../../providers/localization_provider.dart';
import '../../providers/settings_provider.dart';
import '../../services/currency_service.dart';

/// A horizontal scrollable selector for wallets, displaying wallet color,
/// name, and current available balance for quick one-tap switching.
class WalletChipSelector extends ConsumerWidget {
  /// All available wallets in the application.
  final List<Wallet> wallets;

  /// The currently active wallet ID.
  final String? selectedWalletId;

  /// Callback when a wallet is selected.
  final ValueChanged<Wallet> onWalletChanged;

  const WalletChipSelector({
    super.key,
    required this.wallets,
    required this.selectedWalletId,
    required this.onWalletChanged,
  });

  Color _parseColor(String colorStr) {
    try {
      final hex = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF10B981);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.value?.currency ?? 'VND';
    final symbol = CurrencyService.getSymbol(currency);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (wallets.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 6),
          child: Row(
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 15,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                l10n.wallet,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: wallets.map((wallet) {
              final isSelected = wallet.id == selectedWalletId;
              final walletColor = _parseColor(wallet.color);
              final formattedBalance =
                  NumberFormat.compact(locale: 'en_US').format(wallet.currentBalance);

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => onWalletChanged(wallet),
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: isDark ? 0.25 : 0.12)
                            : (isDark ? Colors.grey[850] : Colors.grey[100]),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : (isDark ? Colors.grey[750]! : Colors.grey[300]!),
                          width: isSelected ? 1.5 : 0.8,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 5,
                            backgroundColor: walletColor,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            wallet.name,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : (isDark ? Colors.grey[200] : Colors.grey[800]),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '($formattedBalance $symbol)',
                            style: TextStyle(
                              fontSize: 11,
                              color: isSelected
                                  ? theme.colorScheme.primary.withValues(alpha: 0.85)
                                  : (isDark ? Colors.grey[400] : Colors.grey[600]),
                            ),
                          ),
                          if (isSelected) ...[
                            const SizedBox(width: 4),
                            Icon(
                              Icons.check_circle_rounded,
                              size: 14,
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
