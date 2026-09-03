import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/wallet.dart';
import '../models/wallet_transfer.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/wallet_provider.dart';
import '../utils/localization.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/wallet_form_modal.dart';
import '../widgets/wallet_transfer_modal.dart';

class WalletDetailScreen extends ConsumerStatefulWidget {
  final String walletId;

  const WalletDetailScreen({super.key, required this.walletId});

  @override
  ConsumerState<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends ConsumerState<WalletDetailScreen> {
  String _typeFilter = 'all'; // 'all', 'income', 'expense', 'transfer'
  DateTime? _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  Color _parseColor(String colorStr) {
    try {
      final hex = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF10B981);
    }
  }

  String _formatAmount(double amount, String currency) {
    final symbol = currency == 'VND' ? '₫' : currency;
    final isNegative = amount < 0;
    final absFormatted = NumberFormat('#,###', 'en_US').format(amount.abs());
    return '${isNegative ? '-' : ''}$absFormatted $symbol';
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

  void _previousMonth() {
    if (_selectedMonth == null) {
      setState(() {
        _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
      });
      return;
    }
    setState(() {
      _selectedMonth = DateTime(_selectedMonth!.year, _selectedMonth!.month - 1);
    });
  }

  void _nextMonth() {
    if (_selectedMonth == null) {
      setState(() {
        _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);
      });
      return;
    }
    setState(() {
      _selectedMonth = DateTime(_selectedMonth!.year, _selectedMonth!.month + 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final walletsAsync = ref.watch(walletProvider);
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final transfersAsync = ref.watch(walletTransfersProvider(widget.walletId));
    final settingsAsync = ref.watch(settingsProvider);
    final currency = settingsAsync.value?.currency ?? 'VND';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return walletsAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
      data: (wallets) {
        Wallet? wallet;
        try {
          wallet = wallets.firstWhere((w) => w.id == widget.walletId);
        } catch (_) {
          wallet = null;
        }

        if (wallet == null) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.wallet)),
            body: Center(child: Text(l10n.noWallets)),
          );
        }

        final isNegative = wallet.currentBalance < 0;
        final walletColor = _parseColor(wallet.color);

        // Dynamic Hero gradient
        final primaryColor = isNegative
            ? (isDark ? const Color(0xFF991B1B) : const Color(0xFFDC2626))
            : walletColor;
        final secondaryColor = isNegative
            ? (isDark ? const Color(0xFFB91C1C) : const Color(0xFFEF4444))
            : walletColor.withValues(alpha: 0.82);

        // Filter transactions for this wallet
        final allTx = transactionsAsync.value ?? [];
        final allWalletTx = allTx.where((tx) => tx.walletId == wallet!.id).toList();
        final allTransfers = transfersAsync.value ?? [];

        // Apply Time Filter
        final timeFilteredTx = allWalletTx.where((tx) {
          if (_selectedMonth == null) return true;
          return tx.transactionDate.year == _selectedMonth!.year &&
              tx.transactionDate.month == _selectedMonth!.month;
        }).toList();

        final timeFilteredTransfers = allTransfers.where((tf) {
          if (_selectedMonth == null) return true;
          return tf.transferDate.year == _selectedMonth!.year &&
              tf.transferDate.month == _selectedMonth!.month;
        }).toList();

        // Calculate Inflow and Outflow for selected time
        double totalIn = 0.0;
        double totalOut = 0.0;

        for (final tx in timeFilteredTx) {
          if (tx.type == 'income') {
            totalIn += tx.amount;
          } else {
            totalOut += tx.amount;
          }
        }

        for (final tf in timeFilteredTransfers) {
          if (tf.destinationWalletId == wallet.id) {
            totalIn += tf.amount;
          } else if (tf.sourceWalletId == wallet.id) {
            totalOut += (tf.amount + tf.fee);
          }
        }

        // Apply Type Filter
        List<Transaction> displayTx = [];
        List<WalletTransfer> displayTransfers = [];

        if (_typeFilter == 'all') {
          displayTx = timeFilteredTx;
          displayTransfers = timeFilteredTransfers;
        } else if (_typeFilter == 'income') {
          displayTx = timeFilteredTx.where((tx) => tx.type == 'income').toList();
          displayTransfers = timeFilteredTransfers
              .where((tf) => tf.destinationWalletId == wallet!.id)
              .toList();
        } else if (_typeFilter == 'expense') {
          displayTx = timeFilteredTx.where((tx) => tx.type == 'expense').toList();
          displayTransfers = [];
        } else if (_typeFilter == 'transfer') {
          displayTx = [];
          displayTransfers = timeFilteredTransfers;
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
                          colors: [primaryColor, secondaryColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: secondaryColor.withValues(alpha: 0.28),
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
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              _formatAmount(wallet.currentBalance, currency),
                              style: const TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
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

                    // Time Period Selector Row
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: _selectedMonth != null ? _previousMonth : null,
                          ),
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_selectedMonth == null) {
                                  _selectedMonth = DateTime(
                                    DateTime.now().year,
                                    DateTime.now().month,
                                  );
                                } else {
                                  _selectedMonth = null;
                                }
                              });
                            },
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_rounded,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedMonth != null
                                        ? '${l10n.getMonthName(_selectedMonth!.month)} ${_selectedMonth!.year}'
                                        : l10n.allTime,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: _selectedMonth != null ? _nextMonth : null,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Type Filter Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          _buildFilterChip('all', l10n.filterAll, theme),
                          const SizedBox(width: 8),
                          _buildFilterChip('income', l10n.filterIncome, theme),
                          const SizedBox(width: 8),
                          _buildFilterChip('expense', l10n.filterExpense, theme),
                          const SizedBox(width: 8),
                          _buildFilterChip('transfer', l10n.filterTransfers, theme),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Section Title
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 6,
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
                    if (displayTx.isEmpty && displayTransfers.isEmpty)
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
                        transactions: displayTx,
                        transfers: displayTransfers,
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

  Widget _buildFilterChip(String key, String label, ThemeData theme) {
    final isSelected = _typeFilter == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: theme.colorScheme.primary.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? theme.colorScheme.primary : null,
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() => _typeFilter = key);
        }
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
            trailing: SizedBox(
              width: 105,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${isIncome ? '+' : '-'}${_formatAmount(tx.amount, currency)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                ),
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
              isIncoming ? l10n.transferIn : l10n.transferOut,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
            ),
            subtitle: Text(
              '${DateFormat('dd/MM/yyyy HH:mm').format(tf.transferDate)}${tf.note?.isNotEmpty == true ? ' • ${tf.note}' : ''}${tf.fee > 0 ? ' (${l10n.feeLabel}: ${_formatAmount(tf.fee, currency)})' : ''}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
            trailing: SizedBox(
              width: 105,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  '${isIncoming ? '+' : '-'}${_formatAmount(isIncoming ? tf.amount : (tf.amount + tf.fee), currency)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isIncoming ? Colors.blue : Colors.orange.shade800,
                  ),
                ),
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
