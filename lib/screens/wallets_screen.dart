import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/wallet.dart';
import '../providers/settings_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/localization.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/wallet_card.dart';
import '../widgets/wallet_form_modal.dart';
import '../widgets/wallet_transfer_modal.dart';
import 'wallet_detail_screen.dart';

class WalletsScreen extends ConsumerStatefulWidget {
  const WalletsScreen({super.key});

  @override
  ConsumerState<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends ConsumerState<WalletsScreen> {
  String? _selectedTypeFilter; // null = all

  String _formatAmount(double amount, String currency) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: currency == 'VND' ? '₫' : currency,
      decimalDigits: currency == 'VND' ? 0 : 2,
    );
    return formatter.format(amount);
  }

  void _showDeleteConfirm(BuildContext context, Wallet wallet, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(l10n.deleteWallet),
        content: Text('${l10n.deleteWalletConfirm}\n(${wallet.name})'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.of(ctx).pop();
              await ref.read(walletProvider.notifier).deleteWallet(wallet.id);
            },
            child: Text(l10n.delete, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations(Localizations.localeOf(context).languageCode);
    final theme = Theme.of(context);
    final walletsAsync = ref.watch(walletProvider);
    final totalNetWorth = ref.watch(totalNetWorthProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.value?.currency ?? 'VND';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.wallets),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.swap_horiz),
            tooltip: l10n.transfer,
            onPressed: () => WalletTransferModal.show(context),
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.addWallet,
            onPressed: () => WalletFormModal.show(context),
          ),
        ],
      ),
      body: walletsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('${l10n.error}: $err')),
        data: (allWallets) {
          final filteredWallets = _selectedTypeFilter == null
              ? allWallets
              : allWallets.where((w) => w.type == _selectedTypeFilter).toList();

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.read(walletProvider.notifier).loadWallets(),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      // Hero Net Worth Overview Card
                      Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              theme.colorScheme.primary,
                              theme.colorScheme.primary.withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  l10n.totalNetWorth,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white70,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${allWallets.length} ${l10n.wallets.toLowerCase()}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _formatAmount(totalNetWorth, currency),
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.white,
                                      foregroundColor: theme.colorScheme.primary,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.swap_horiz, size: 18),
                                    label: Text(
                                      l10n.transfer,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () =>
                                        WalletTransferModal.show(context),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.white,
                                      side: const BorderSide(color: Colors.white),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                    icon: const Icon(Icons.add, size: 18),
                                    label: Text(
                                      l10n.addWallet,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    onPressed: () =>
                                        WalletFormModal.show(context),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Horizontal Filter Chips
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        alignment: Alignment.centerLeft,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              _buildFilterChip(
                                label: l10n.all,
                                isSelected: _selectedTypeFilter == null,
                                onTap: () =>
                                    setState(() => _selectedTypeFilter = null),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: l10n.walletCash,
                                isSelected: _selectedTypeFilter == 'cash',
                                onTap: () => setState(
                                    () => _selectedTypeFilter = 'cash'),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: l10n.walletBank,
                                isSelected: _selectedTypeFilter == 'bank',
                                onTap: () => setState(
                                    () => _selectedTypeFilter = 'bank'),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: l10n.walletEwallet,
                                isSelected: _selectedTypeFilter == 'ewallet',
                                onTap: () => setState(
                                    () => _selectedTypeFilter = 'ewallet'),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: l10n.walletCredit,
                                isSelected: _selectedTypeFilter == 'credit',
                                onTap: () => setState(
                                    () => _selectedTypeFilter = 'credit'),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterChip(
                                label: l10n.walletSavings,
                                isSelected: _selectedTypeFilter == 'savings',
                                onTap: () => setState(
                                    () => _selectedTypeFilter = 'savings'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Wallets List
                      if (filteredWallets.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            vertical: 48,
                            horizontal: 24,
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 64,
                                color: Colors.grey.shade400,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                l10n.noWallets,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                l10n.noWalletsDesc,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        ...filteredWallets.map((wallet) {
                          return WalletCard(
                            wallet: wallet,
                            currency: currency,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      WalletDetailScreen(walletId: wallet.id),
                                ),
                              );
                            },
                            onEdit: () => WalletFormModal.show(
                              context,
                              walletToEdit: wallet,
                            ),
                            onDelete: () =>
                                _showDeleteConfirm(context, wallet, l10n),
                            onSetDefault: () => ref
                                .read(walletProvider.notifier)
                                .setDefaultWallet(wallet.id),
                            onTransfer: () => WalletTransferModal.show(
                              context,
                              initialSourceWalletId: wallet.id,
                            ),
                          );
                        }),
                    ],
                  ),
                ),
              ),
              const BannerAdWidget(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurface,
      ),
      onSelected: (_) => onTap(),
    );
  }
}
