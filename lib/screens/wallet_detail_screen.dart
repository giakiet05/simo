import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/wallet_transfer.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/localization.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/wallet_form_modal.dart';
import '../widgets/wallet_transfer_modal.dart';

class WalletDetailScreen extends ConsumerWidget {
  final String walletId;

  const WalletDetailScreen({super.key, required this.walletId});

  Color _parseColor(String colorStr) {
    try {
      final hex = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF10B981);
    }
  }

  String _formatAmount(double amount, String currency) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: currency == 'VND' ? '₫' : currency,
      decimalDigits: currency == 'VND' ? 0 : 2,
    );
    return formatter.format(amount);
  }

  String _getTypeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'bank':
        return l10n.walletBank;
      case 'ewallet':
        return l10n.walletEwallet;
      case 'credit':
        return l10n.walletCredit;
      case 'savings':
        return l10n.walletSavings;
      case 'other':
        return l10n.walletOther;
      case 'cash':
      default:
        return l10n.walletCash;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations(Localizations.localeOf(context).languageCode);
    final walletsAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final transfersAsync = ref.watch(walletTransfersProvider(walletId));
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.value?.currency ?? 'VND';
    final theme = Theme.of(context);

    return walletsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (wallets) {
        Wallet? wallet;
        try {
          wallet = wallets.firstWhere((w) => w.id == walletId);
        } catch (_) {
          wallet = null;
        }

        if (wallet == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.wallet)),
            body: Center(child: Text(l10n.noWallets)),
          );
        }

        final color = _parseColor(wallet.color);

        // Filter transactions for this wallet
        final allTx = transactionsAsync.value ?? [];
        final walletTx = allTx.where((tx) => tx.walletId == wallet!.id).toList();

        // Calculate Inflow and Outflow
        final transfers = transfersAsync.value ?? [];
        double totalIn = 0.0;
        double totalOut = 0.0;

        for (final tx in walletTx) {
          if (tx.type == 'income') {
            totalIn += tx.amount;
          } else {
            totalOut += tx.amount;
          }
        }

        for (final tf in transfers) {
          if (tf.destinationWalletId == wallet.id) {
            totalIn += tf.amount;
          } else if (tf.sourceWalletId == wallet.id) {
            totalOut += (tf.amount + tf.fee);
          }
        }

        final categories = categoriesAsync.value ?? [];
        final Map<String, dynamic> categoryMap = {for (var c in categories) c.id: c};

        return Scaffold(
          appBar: AppBar(
            title: Text(wallet.name),
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.swap_horiz),
                tooltip: l10n.transfer,
                onPressed: () => WalletTransferModal.show(
                  context,
                  initialSourceWalletId: wallet!.id,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: l10n.editWallet,
                onPressed: () => WalletFormModal.show(
                  context,
                  walletToEdit: wallet,
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 24),
                  children: [
                    // Hero Card
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [color, color.withValues(alpha: 0.8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
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
                                _getTypeLabel(wallet.type, l10n),
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.white70,
                                ),
                              ),
                              if (wallet.isDefault)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.25),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    l10n.defaultWalletBadge,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatAmount(wallet.currentBalance, currency),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.totalInflow,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '+${_formatAmount(totalIn, currency)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        l10n.totalOutflow,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '-${_formatAmount(totalOut, currency)}',
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
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
                    ),

                    // Section Title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      child: Text(
                        l10n.walletStatement,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    // Statement List (Transactions + Transfers)
                    if (walletTx.isEmpty && transfers.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        child: Center(
                          child: Text(
                            l10n.noTransactions,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                      )
                    else
                      ..._buildTimelineItems(
                        context: context,
                        wallet: wallet,
                        transactions: walletTx,
                        transfers: transfers,
                        categoryMap: categoryMap,
                        currency: currency,
                        l10n: l10n,
                      ),
                  ],
                ),
              ),
              const BannerAdWidget(),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildTimelineItems({
    required BuildContext context,
    required Wallet wallet,
    required List<Transaction> transactions,
    required List<WalletTransfer> transfers,
    required Map<String, dynamic> categoryMap,
    required String currency,
    required AppLocalizations l10n,
  }) {
    // Combine and sort by date descending
    final items = <_TimelineItem>[];

    for (final tx in transactions) {
      items.add(_TimelineItem(
        date: tx.transactionDate,
        isTransaction: true,
        transaction: tx,
      ));
    }

    for (final tf in transfers) {
      items.add(_TimelineItem(
        date: tf.transferDate,
        isTransaction: false,
        transfer: tf,
      ));
    }

    items.sort((a, b) => b.date.compareTo(a.date));

    final theme = Theme.of(context);

    return items.map((item) {
      if (item.isTransaction) {
        final tx = item.transaction!;
        final isIncome = tx.type == 'income';
        final cat = tx.categoryId != null ? categoryMap[tx.categoryId] : null;
        final catName = cat != null
            ? l10n.translateCategoryName(cat.id, cat.name)
            : l10n.noCategory;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isIncome
                  ? Colors.green.withValues(alpha: 0.15)
                  : Colors.red.withValues(alpha: 0.15),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                color: isIncome ? Colors.green : Colors.red,
                size: 20,
              ),
            ),
            title: Text(
              tx.note?.isNotEmpty == true ? tx.note! : catName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy HH:mm').format(tx.transactionDate)} • $catName',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: Text(
              '${isIncome ? '+' : '-'}${_formatAmount(tx.amount, currency)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),
          ),
        );
      } else {
        final tf = item.transfer!;
        final isIncoming = tf.destinationWalletId == wallet.id;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
          ),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue.withValues(alpha: 0.15),
              child: const Icon(Icons.swap_horiz, color: Colors.blue, size: 20),
            ),
            title: Text(
              isIncoming ? 'Chuyển tiền đến ví' : 'Chuyển tiền đi',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy HH:mm').format(tf.transferDate)}${tf.note?.isNotEmpty == true ? ' • ${tf.note}' : ''}${tf.fee > 0 ? ' (Phí: ${_formatAmount(tf.fee, currency)})' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: Text(
              '${isIncoming ? '+' : '-'}${_formatAmount(isIncoming ? tf.amount : (tf.amount + tf.fee), currency)}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isIncoming ? Colors.blue : Colors.orange.shade800,
              ),
            ),
          ),
        );
      }
    }).toList();
  }
}

class _TimelineItem {
  final DateTime date;
  final bool isTransaction;
  final Transaction? transaction;
  final WalletTransfer? transfer;

  _TimelineItem({
    required this.date,
    required this.isTransaction,
    this.transaction,
    this.transfer,
  });
}
