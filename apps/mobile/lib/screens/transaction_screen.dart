import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../services/currency_service.dart';
import '../widgets/banner_ad_widget.dart';
import 'transaction_form_screen.dart';
import '../widgets/category_icon_widget.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet.dart';
import '../models/transaction_filter_criteria.dart';
import '../services/transaction_filter_service.dart';
import '../widgets/transaction_filter_bottom_sheet.dart';
import '../widgets/quick_filter_chips_bar.dart';
import '../widgets/transaction/transaction_detail_bottom_sheet.dart';

class TransactionScreen extends ConsumerStatefulWidget {
  final String? initialTypeFilter;
  const TransactionScreen({super.key, this.initialTypeFilter});

  @override
  ConsumerState<TransactionScreen> createState() => TransactionScreenState();
}

class _DayGroup {
  final DateTime date;
  final List<Transaction> transactions;
  final double totalIncome;
  final double totalExpense;

  const _DayGroup({
    required this.date,
    required this.transactions,
    required this.totalIncome,
    required this.totalExpense,
  });
}

class TransactionScreenState extends ConsumerState<TransactionScreen> {
  TransactionFilterCriteria _filterCriteria = const TransactionFilterCriteria();
  final TransactionFilterService _filterService = TransactionFilterService();

  int _currentPage = 1;
  final int _limit = 20;
  bool _hasMore = true;
  final ScrollController _scrollController = ScrollController();

  // Selection mode
  bool _isSelectionMode = false;
  bool get isSelectionMode => _isSelectionMode;
  final Set<String> _selectedTransactionIds = {};

  // Search mode
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    if (widget.initialTypeFilter != null) {
      _filterCriteria = _filterCriteria.copyWith(type: widget.initialTypeFilter);
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
      if (_hasMore) {
        _loadMore();
      }
    }
  }

  void _loadMore() {
    setState(() {
      _currentPage++;
    });
  }

  List<Transaction> _applyFilters(
    List<Transaction> transactions,
    Map<String, Category> categoryMap,
    Map<String, Wallet> walletMap,
  ) {
    return _filterService.applyFilter(
      allTransactions: transactions,
      criteria: _filterCriteria.copyWith(searchQuery: _searchQuery),
      categoryMap: categoryMap,
      walletMap: walletMap,
    );
  }

  List<_DayGroup> _groupTransactionsByDay(List<Transaction> transactions) {
    final List<_DayGroup> groups = [];
    if (transactions.isEmpty) return groups;

    DateTime? currentDay;
    List<Transaction> currentList = [];
    double dayIncome = 0;
    double dayExpense = 0;

    for (final tx in transactions) {
      final txDate = tx.transactionDate;
      final normalized = DateTime(txDate.year, txDate.month, txDate.day);

      if (currentDay == null || !DateUtils.isSameDay(currentDay, normalized)) {
        if (currentDay != null) {
          groups.add(_DayGroup(
            date: currentDay,
            transactions: currentList,
            totalIncome: dayIncome,
            totalExpense: dayExpense,
          ));
        }
        currentDay = normalized;
        currentList = [tx];
        dayIncome = tx.type == 'income' ? tx.amount : 0;
        dayExpense = tx.type == 'expense' ? tx.amount : 0;
      } else {
        currentList.add(tx);
        if (tx.type == 'income') {
          dayIncome += tx.amount;
        } else {
          dayExpense += tx.amount;
        }
      }
    }

    if (currentDay != null && currentList.isNotEmpty) {
      groups.add(_DayGroup(
        date: currentDay,
        transactions: currentList,
        totalIncome: dayIncome,
        totalExpense: dayExpense,
      ));
    }

    return groups;
  }

  String _getDayLabel(DateTime date, dynamic l10n) {
    final now = DateTime.now();
    final isToday = date.year == now.year && date.month == now.month && date.day == now.day;
    final yesterday = now.subtract(const Duration(days: 1));
    final isYesterday = date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;

    final isVi = l10n.locale == 'vi';

    if (isToday) {
      return isVi ? 'Hôm nay' : 'Today';
    }
    if (isYesterday) {
      return isVi ? 'Hôm qua' : 'Yesterday';
    }

    if (isVi) {
      switch (date.weekday) {
        case DateTime.monday:
          return 'Thứ Hai';
        case DateTime.tuesday:
          return 'Thứ Ba';
        case DateTime.wednesday:
          return 'Thứ Tư';
        case DateTime.thursday:
          return 'Thứ Năm';
        case DateTime.friday:
          return 'Thứ Sáu';
        case DateTime.saturday:
          return 'Thứ Bảy';
        case DateTime.sunday:
          return 'Chủ Nhật';
        default:
          return '';
      }
    } else {
      return DateFormat('EEEE').format(date);
    }
  }

  Widget _buildTransactionItem(
    Transaction transaction,
    Category? category,
    String symbol,
    dynamic l10n,
    bool isDark,
    ThemeData theme,
  ) {
    final categoryName = category != null
        ? l10n.translateCategoryName(category.id, category.name)
        : l10n.noCategory;
    final isSelected = _selectedTransactionIds.contains(transaction.id);
    final isIncome = transaction.type == 'income';
    final formattedAmount = NumberFormat('#,###', 'en_US').format(transaction.amount);

    return Material(
      color: isSelected ? Colors.blue.withValues(alpha: isDark ? 0.25 : 0.12) : Colors.transparent,
      child: InkWell(
        onTap: _isSelectionMode
            ? () {
                setState(() {
                  if (isSelected) {
                    _selectedTransactionIds.remove(transaction.id);
                  } else {
                    _selectedTransactionIds.add(transaction.id);
                  }
                });
              }
            : () => _showActionMenu(context, ref, transaction),
        onLongPress: _isSelectionMode
            ? null
            : () {
                setState(() {
                  _isSelectionMode = true;
                  _selectedTransactionIds.add(transaction.id);
                });
              },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              if (_isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: Checkbox(
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                      value: isSelected,
                      onChanged: (value) {
                        setState(() {
                          if (value == true) {
                            _selectedTransactionIds.add(transaction.id);
                          } else {
                            _selectedTransactionIds.remove(transaction.id);
                          }
                        });
                      },
                    ),
                  ),
                ),
              CategoryIconWidget(
                category: category,
                iconName: category == null
                    ? (isIncome ? 'attach_money' : 'shopping_cart')
                    : null,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      categoryName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (transaction.note != null && transaction.note!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        transaction.note!,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ] else if (transaction.formula != null && transaction.formula!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        transaction.formula!,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: Colors.grey[500],
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        '${isIncome ? '+' : '-'}$formattedAmount $symbol',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isIncome ? Colors.green : Colors.red,
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('HH:mm').format(transaction.transactionDate),
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.grey[500] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final walletsAsync = ref.watch(walletProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final l10n = ref.watch(localizationProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.white54 : Colors.black45;
    final allTransactions = transactionsAsync.value ?? [];
    final categories = categoriesAsync.value ?? [];
    final wallets = walletsAsync.value ?? [];
    final categoryMap = {for (var cat in categories) cat.id: cat};
    final walletMap = {for (var w in wallets) w.id: w};
    final filteredTransactions = _applyFilters(allTransactions, categoryMap, walletMap);
    final totalItems = filteredTransactions.length;
    final endIndex = (_currentPage * _limit).clamp(0, totalItems);
    final paginatedTransactions = filteredTransactions.take(endIndex).toList();
    final isAllSelected = paginatedTransactions.isNotEmpty &&
        paginatedTransactions.every((t) => _selectedTransactionIds.contains(t.id));

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectionMode) {
          setState(() {
            _isSelectionMode = false;
            _selectedTransactionIds.clear();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: _isSelectionMode
              ? Text('${_selectedTransactionIds.length} ${l10n.transaction}')
              : _isSearching
                  ? TextField(
                      controller: _searchController,
                      autofocus: true,
                      cursorColor: textColor,
                      decoration: InputDecoration(
                        hintText: l10n.locale == 'vi'
                            ? 'Tìm theo nội dung, danh mục, ví, số tiền (50k, 1.5tr)...'
                            : 'Search note, category, wallet, amount (50k, 1.5m)...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: hintColor, fontSize: 15),
                      ),
                      style: TextStyle(color: textColor, fontSize: 16),
                      onChanged: (val) {
                        setState(() {
                          _searchQuery = val;
                          _currentPage = 1; // reset pagination when searching
                        });
                      },
                    )
                  : Text(l10n.transactions),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          leading: _isSelectionMode
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _isSelectionMode = false;
                      _selectedTransactionIds.clear();
                    });
                  },
                )
              : _isSearching
                  ? IconButton(
                      icon: Icon(Icons.arrow_back, color: textColor),
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : IconButton(
                      icon: const Icon(Icons.checklist_rounded),
                      tooltip: l10n.selectMultiple,
                      onPressed: () {
                        setState(() {
                          _isSelectionMode = true;
                        });
                      },
                    ),
          actions: _isSelectionMode
              ? [
                  IconButton(
                    icon: Icon(isAllSelected ? Icons.deselect : Icons.select_all),
                    tooltip: isAllSelected
                        ? (l10n.locale == 'vi' ? 'Bỏ chọn tất cả' : 'Deselect all')
                        : (l10n.locale == 'vi' ? 'Chọn tất cả' : 'Select all'),
                    onPressed: paginatedTransactions.isEmpty
                        ? null
                        : () {
                            setState(() {
                              if (isAllSelected) {
                                _selectedTransactionIds.clear();
                              } else {
                                _selectedTransactionIds
                                    .addAll(paginatedTransactions.map((t) => t.id));
                              }
                            });
                          },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    tooltip: l10n.delete,
                    onPressed: _selectedTransactionIds.isEmpty
                        ? null
                        : () => _showDeleteMultipleDialog(context),
                  ),
                ]
              : [
                  if (!_isSearching) ...[
                    IconButton(
                      icon: Badge(
                        isLabelVisible: _filterCriteria.hasActiveFilters,
                        smallSize: 8,
                        child: Icon(
                          Icons.tune_rounded,
                          color: _filterCriteria.hasActiveFilters
                              ? Theme.of(context).colorScheme.primary
                              : textColor,
                        ),
                      ),
                      tooltip: l10n.locale == 'vi' ? 'Bộ lọc' : 'Filter',
                      onPressed: () => _showFilterSheet(context, ref),
                    ),
                    IconButton(
                      icon: Icon(Icons.search, color: textColor),
                      tooltip: l10n.locale == 'vi' ? 'Tìm kiếm' : 'Search',
                      onPressed: () {
                        setState(() {
                          _isSearching = true;
                        });
                      },
                    ),
                  ],
                  if (_isSearching) ...[
                    if (_searchQuery.isNotEmpty)
                      IconButton(
                        icon: Icon(Icons.clear, color: textColor),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                            _searchController.clear();
                          });
                        },
                      ),
                    IconButton(
                      icon: Badge(
                        isLabelVisible: _filterCriteria.hasActiveFilters,
                        smallSize: 8,
                        child: Icon(
                          Icons.tune_rounded,
                          color: _filterCriteria.hasActiveFilters
                              ? Theme.of(context).colorScheme.primary
                              : textColor,
                        ),
                      ),
                      tooltip: l10n.locale == 'vi' ? 'Bộ lọc' : 'Filter',
                      onPressed: () => _showFilterSheet(context, ref),
                    ),
                  ],
                ],
        ),
        body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
        data: (categories) {
          return transactionsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
            data: (allTransactions) {
              final wallets = walletsAsync.value ?? [];
              final categoryMap = {
                for (var cat in categories) cat.id: cat
              };
              final walletMap = {
                for (var w in wallets) w.id: w
              };

              // Apply filters & fuzzy search
              final filteredTransactions = _applyFilters(allTransactions, categoryMap, walletMap);

              // Apply pagination
              final totalItems = filteredTransactions.length;
              final endIndex = (_currentPage * _limit).clamp(0, totalItems);
              final paginatedTransactions = filteredTransactions.take(endIndex).toList();
              _hasMore = endIndex < totalItems;

              final dayGroups = _groupTransactionsByDay(paginatedTransactions);
              final currency = settingsAsync.value?.currency ?? 'VND';
              final symbol = CurrencyService.getSymbol(currency);

              return Column(
                children: [
                  if (!_isSelectionMode)
                    QuickFilterChipsBar(
                      criteria: _filterCriteria,
                      wallets: wallets,
                      l10n: l10n,
                      onFilterChanged: (newCriteria) {
                        setState(() {
                          _filterCriteria = newCriteria;
                          _currentPage = 1;
                        });
                      },
                      onOpenFilterSheet: () => _showFilterSheet(context, ref),
                    ),
                  if (categories.isEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.amber[50],
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber, size: 16, color: Colors.orange),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.noCategoriesWarning,
                              style: TextStyle(fontSize: 12, color: Colors.orange[900]),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Expanded(
                    child: paginatedTransactions.isEmpty
                        ? Center(child: Text(l10n.noTransactions))
                        : ListView.builder(
                      controller: _scrollController,
                      itemCount: dayGroups.length + (_hasMore ? 1 : 0),
                      padding: const EdgeInsets.only(top: 6, bottom: 80),
                      itemBuilder: (context, groupIndex) {
                        if (groupIndex == dayGroups.length) {
                          // Loading indicator at bottom
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final group = dayGroups[groupIndex];
                        final dayDate = group.date;

                        // Check if we need to show month header
                        final showMonthHeader = groupIndex == 0 ||
                            dayGroups[groupIndex - 1].date.month != dayDate.month ||
                            dayGroups[groupIndex - 1].date.year != dayDate.year;

                        final monthNum = dayDate.month;
                        final year = dayDate.year;
                        final monthHeaderText = l10n.locale == 'vi'
                            ? 'Tháng $monthNum/$year'
                            : '${l10n.getMonthName(monthNum)} $year';

                        final dateFormatted = DateFormat('dd/MM/yyyy').format(dayDate);
                        final dayLabel = _getDayLabel(dayDate, l10n);
                        final dayTitle = '$dayLabel, $dateFormatted';

                        final dayCard = Card(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(
                              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                              width: 1,
                            ),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Day Header
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                color: isDark ? Colors.grey[850] : Colors.grey[100],
                                child: Text(
                                  dayTitle,
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.white : Colors.black87,
                                  ),
                                ),
                              ),
                              // List of transactions for this day
                              for (int i = 0; i < group.transactions.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    thickness: 0.6,
                                    indent: 58,
                                    endIndent: 14,
                                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                                  ),
                                _buildTransactionItem(
                                  group.transactions[i],
                                  categoryMap[group.transactions[i].categoryId],
                                  symbol,
                                  l10n,
                                  isDark,
                                  theme,
                                ),
                              ],
                            ],
                          ),
                        );

                        if (showMonthHeader) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                margin: EdgeInsets.only(
                                  top: groupIndex == 0 ? 4 : 16,
                                  bottom: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.teal.withValues(alpha: 0.2)
                                      : Colors.teal[50],
                                  border: Border(
                                    top: BorderSide(
                                      color: isDark
                                          ? Colors.teal.withValues(alpha: 0.35)
                                          : Colors.teal[100]!,
                                      width: 0.8,
                                    ),
                                    bottom: BorderSide(
                                      color: isDark
                                          ? Colors.teal.withValues(alpha: 0.35)
                                          : Colors.teal[100]!,
                                      width: 0.8,
                                    ),
                                  ),
                                ),
                                child: Text(
                                  monthHeaderText,
                                  style: TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? Colors.teal[100] : Colors.teal[900],
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              dayCard,
                            ],
                          );
                        }

                        return dayCard;
                      },
                    ),
                  ),
                  if (_isSelectionMode && _selectedTransactionIds.isNotEmpty)
                    _buildBulkActionBar(context, ref, l10n, theme, isDark)
                  else
                    const BannerAdWidget(key: ValueKey('transaction_banner_ad')),
                ],
              );
            },
          );
        },
        ),
        floatingActionButton: _isSelectionMode
            ? null
            : FloatingActionButton(
                heroTag: 'transaction_fab',
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TransactionFormScreen()),
                  );
                },
                child: const Icon(Icons.add),
              ),
      ),
    );
  }

  Future<void> _showFilterSheet(BuildContext context, WidgetRef ref) async {
    final l10n = ref.read(localizationProvider);
    final wallets = ref.read(walletProvider).value ?? [];
    final categories = ref.read(categoryProvider).value ?? [];
    final allTransactions = ref.read(transactionProvider).value ?? [];

    final newCriteria = await TransactionFilterBottomSheet.show(
      context: context,
      initialCriteria: _filterCriteria,
      wallets: wallets,
      categories: categories,
      l10n: l10n,
      allTransactions: allTransactions,
    );

    if (newCriteria != null) {
      setState(() {
        _filterCriteria = newCriteria;
        _currentPage = 1;
      });
    }
  }

  void _showDeleteMultipleDialog(BuildContext context) {
    final l10n = ref.read(localizationProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTransaction),
        content: Text(
          '${l10n.deleteTransactionConfirm}\n${_selectedTransactionIds.length} ${l10n.transaction}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(transactionProvider.notifier)
                    .deleteTransactions(_selectedTransactionIds.toList());
                if (context.mounted) {
                  Navigator.pop(context);
                  setState(() {
                    _isSelectionMode = false;
                    _selectedTransactionIds.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.transactionDeleted)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.error}: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  void _showActionMenu(
      BuildContext context, WidgetRef ref, Transaction transaction) {
    TransactionDetailBottomSheet.show(
      context,
      transaction: transaction,
      onEdit: () => _showEditDialog(context, ref, transaction),
      onDelete: () => _showDeleteDialog(context, ref, transaction),
    );
  }

  void _showEditDialog(
      BuildContext context, WidgetRef ref, Transaction transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TransactionFormScreen(
          editTransactionId: transaction.id,
          editType: transaction.type,
          editAmount: transaction.amount.toString(),
          editFormula: transaction.formula,
          editCategoryId: transaction.categoryId,
          editWalletId: transaction.walletId,
          editNote: transaction.note,
          editTransactionDate: transaction.transactionDate,
          editCreatedAt: transaction.createdAt,
        ),
      ),
    );
  }

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, Transaction transaction) {
    final l10n = ref.read(localizationProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteTransaction),
        content: Text(l10n.deleteTransactionConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref
                    .read(transactionProvider.notifier)
                    .deleteTransactions([transaction.id]);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.transactionDeleted)),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.error}: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  /// Builds the floating bulk action bar at the bottom when items are selected.
  Widget _buildBulkActionBar(
    BuildContext context,
    WidgetRef ref,
    dynamic l10n,
    ThemeData theme,
    bool isDark,
  ) {
    final allTransactions = ref.watch(transactionProvider).value ?? [];
    final selectedTxs = allTransactions.where((t) => _selectedTransactionIds.contains(t.id)).toList();
    final hasExpense = selectedTxs.any((t) => t.type == 'expense');
    final hasIncome = selectedTxs.any((t) => t.type == 'income');
    final isMixedType = hasExpense && hasIncome;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
            width: 0.8,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildBulkActionButton(
              icon: Icons.account_balance_wallet_outlined,
              label: l10n.locale == 'vi' ? 'Đổi ví' : 'Change wallet',
              color: theme.colorScheme.primary,
              onTap: () => _showBulkChangeWalletSheet(context, ref),
            ),
            _buildBulkActionButton(
              icon: Icons.category_outlined,
              label: l10n.locale == 'vi' ? 'Đổi mục' : 'Category',
              color: isMixedType ? Colors.grey : Colors.orange,
              opacity: isMixedType ? 0.35 : 1.0,
              onTap: () {
                if (isMixedType) {
                  ScaffoldMessenger.of(context).clearSnackBars();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        l10n.locale == 'vi'
                            ? 'Chỉ có thể đổi danh mục khi các giao dịch cùng loại Thu hoặc Chi'
                            : 'Can only change category when transactions are of the same type (Income or Expense)',
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
                  return;
                }
                _showBulkChangeCategorySheet(context, ref);
              },
            ),
            _buildBulkActionButton(
              icon: Icons.calendar_today_outlined,
              label: l10n.locale == 'vi' ? 'Đổi ngày' : 'Change date',
              color: Colors.teal,
              onTap: () => _showBulkChangeDatePicker(context, ref),
            ),
            _buildBulkActionButton(
              icon: Icons.delete_outline,
              label: l10n.delete,
              color: Colors.red,
              onTap: () => _showDeleteMultipleDialog(context),
            ),
          ],
        ),
      ),
    ),
  );
}

  /// Helper widget to build each action button in the bulk action bar.
  Widget _buildBulkActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    double opacity = 1.0,
  }) {
    return Opacity(
      opacity: opacity,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _parseColor(String colorStr) {
    try {
      final hex = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return const Color(0xFF10B981);
    }
  }

  /// Opens a bottom sheet for the user to pick a target wallet to bulk assign.
  Future<void> _showBulkChangeWalletSheet(BuildContext context, WidgetRef ref) async {
    final wallets = ref.read(walletProvider).value ?? [];
    final l10n = ref.read(localizationProvider);
    final settingsAsync = ref.read(settingsProvider);
    final currency = settingsAsync.value?.currency ?? 'VND';
    final symbol = CurrencyService.getSymbol(currency);

    if (wallets.isEmpty) return;

    final selectedWallet = await showModalBottomSheet<Wallet>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.locale == 'vi' ? 'Chuyển sang ví khác' : 'Move to another wallet',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: wallets.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final wallet = wallets[index];
                      final walletColor = _parseColor(wallet.color);
                      final formattedBalance = NumberFormat('#,###', 'en_US').format(wallet.currentBalance);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: walletColor.withValues(alpha: 0.15),
                          child: Icon(Icons.account_balance_wallet, color: walletColor),
                        ),
                        title: Text(wallet.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('$formattedBalance $symbol'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, wallet),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedWallet != null && context.mounted) {
      try {
        final count = _selectedTransactionIds.length;
        await ref
            .read(transactionProvider.notifier)
            .updateTransactionsWallet(_selectedTransactionIds.toList(), selectedWallet.id);

        if (context.mounted) {
          setState(() {
            _isSelectionMode = false;
            _selectedTransactionIds.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.locale == 'vi'
                    ? 'Đã chuyển $count giao dịch sang ví ${selectedWallet.name}'
                    : 'Moved $count transactions to wallet ${selectedWallet.name}',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.error}: $e')),
          );
        }
      }
    }
  }

  /// Opens a bottom sheet for the user to pick a target category to bulk assign.
  Future<void> _showBulkChangeCategorySheet(BuildContext context, WidgetRef ref) async {
    final categories = ref.read(categoryProvider).value ?? [];
    final allTransactions = ref.read(transactionProvider).value ?? [];
    final l10n = ref.read(localizationProvider);

    if (categories.isEmpty) return;

    // Filter categories strictly by transaction type in the selection
    final selectedTxs = allTransactions.where((t) => _selectedTransactionIds.contains(t.id)).toList();
    final hasExpense = selectedTxs.any((t) => t.type == 'expense');
    final hasIncome = selectedTxs.any((t) => t.type == 'income');

    if (hasExpense && hasIncome) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.locale == 'vi'
                ? 'Chỉ có thể đổi danh mục khi các giao dịch cùng loại Thu hoặc Chi'
                : 'Can only change category when transactions are of the same type (Income or Expense)',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final targetType = hasIncome ? 'income' : 'expense';
    final filteredCategories = categories.where((c) => c.type == targetType).toList();

    if (filteredCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            l10n.locale == 'vi'
                ? 'Không có danh mục nào thuộc loại này'
                : 'No categories available for this type',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final selectedCategory = await showModalBottomSheet<Category>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.locale == 'vi' ? 'Đổi danh mục giao dịch' : 'Change category',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: filteredCategories.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final cat = filteredCategories[index];
                      final catName = l10n.translateCategoryName(cat.id, cat.name);
                      return ListTile(
                        leading: CategoryIconWidget(category: cat, size: 36),
                        title: Text(catName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          cat.type == 'income'
                              ? (l10n.locale == 'vi' ? 'Thu nhập' : 'Income')
                              : (l10n.locale == 'vi' ? 'Chi phí' : 'Expense'),
                          style: TextStyle(
                            fontSize: 12,
                            color: cat.type == 'income' ? Colors.green : Colors.red,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => Navigator.pop(context, cat),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedCategory != null && context.mounted) {
      try {
        final count = _selectedTransactionIds.length;
        await ref
            .read(transactionProvider.notifier)
            .updateTransactionsCategory(_selectedTransactionIds.toList(), selectedCategory.id);

        if (context.mounted) {
          final catName = l10n.translateCategoryName(selectedCategory.id, selectedCategory.name);
          setState(() {
            _isSelectionMode = false;
            _selectedTransactionIds.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.locale == 'vi'
                    ? 'Đã đổi $count giao dịch sang mục $catName'
                    : 'Changed $count transactions to category $catName',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.error}: $e')),
          );
        }
      }
    }
  }

  /// Opens a DatePicker for the user to bulk change the transaction date.
  Future<void> _showBulkChangeDatePicker(BuildContext context, WidgetRef ref) async {
    final l10n = ref.read(localizationProvider);
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: Locale(l10n.locale),
    );

    if (pickedDate != null && context.mounted) {
      try {
        final count = _selectedTransactionIds.length;
        await ref
            .read(transactionProvider.notifier)
            .updateTransactionsDate(_selectedTransactionIds.toList(), pickedDate);

        if (context.mounted) {
          final formatted = DateFormat('dd/MM/yyyy').format(pickedDate);
          setState(() {
            _isSelectionMode = false;
            _selectedTransactionIds.clear();
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n.locale == 'vi'
                    ? 'Đã chuyển $count giao dịch sang ngày $formatted'
                    : 'Moved $count transactions to date $formatted',
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${l10n.error}: $e')),
          );
        }
      }
    }
  }
}
