import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/icon_data.dart';
import '../services/currency_service.dart';
import '../widgets/banner_ad_widget.dart';
import 'transaction_form_screen.dart';
import '../widgets/category_icon_widget.dart';

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
  // Filter states
  String _timeFilter = 'all'; // all, this_month, last_month, last_3_months, custom
  String? _typeFilter; // null = all, 'income', 'expense'
  String? _categoryFilter; // null = all, categoryId
  double? _minAmount;
  double? _maxAmount;
  DateTime? _startDate;
  DateTime? _endDate;
  int? _startMonth;
  int? _startYear;
  int? _endMonth;
  int? _endYear;

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
      _typeFilter = widget.initialTypeFilter;
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

  int _getActiveFilterCount() {
    int count = 0;
    if (_typeFilter != null) count++;
    if (_categoryFilter != null) count++;
    if (_minAmount != null) count++;
    if (_maxAmount != null) count++;
    if (_timeFilter == 'custom' && (_startDate != null || _endDate != null)) count++;
    return count;
  }

  List<Transaction> _applyFilters(List<Transaction> transactions) {
    var filtered = transactions;

    // Time filter
    final now = DateTime.now();
    if (_timeFilter == 'all') {
      // No time filter
    } else if (_timeFilter == 'this_month') {
      filtered = filtered.where((tx) {
        return tx.transactionDate.year == now.year && tx.transactionDate.month == now.month;
      }).toList();
    } else if (_timeFilter == 'last_month') {
      final lastMonth = DateTime(now.year, now.month - 1);
      filtered = filtered.where((tx) {
        return tx.transactionDate.year == lastMonth.year && tx.transactionDate.month == lastMonth.month;
      }).toList();
    } else if (_timeFilter == 'last_3_months') {
      final threeMonthsAgo = DateTime(now.year, now.month - 3);
      filtered = filtered.where((tx) => tx.transactionDate.isAfter(threeMonthsAgo)).toList();
    } else if (_timeFilter == 'custom') {
      if (_startDate != null) {
        filtered = filtered.where((tx) => tx.transactionDate.isAfter(_startDate!)).toList();
      }
      if (_endDate != null) {
        filtered = filtered.where((tx) => tx.transactionDate.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
      }
    }

    // Type filter
    if (_typeFilter != null) {
      filtered = filtered.where((tx) => tx.type == _typeFilter).toList();
    }

    // Category filter
    if (_categoryFilter != null) {
      filtered = filtered.where((tx) => tx.categoryId == _categoryFilter).toList();
    }

    // Amount filter
    if (_minAmount != null) {
      filtered = filtered.where((tx) => tx.amount >= _minAmount!).toList();
    }
    if (_maxAmount != null) {
      filtered = filtered.where((tx) => tx.amount <= _maxAmount!).toList();
    }

    // Search query filter
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((tx) {
        final noteMatch = tx.note?.toLowerCase().contains(q) ?? false;
        final amountMatch = tx.amount.toString().contains(q);
        return noteMatch || amountMatch;
      }).toList();
    }

    filtered.sort((a, b) {
      int dateCmp = b.transactionDate.compareTo(a.transactionDate);
      if (dateCmp != 0) return dateCmp;
      
      return b.createdAt.compareTo(a.createdAt);
    });

    return filtered;
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
    final settingsAsync = ref.watch(settingsProvider);
    final l10n = ref.watch(localizationProvider);

    final filterCount = _getActiveFilterCount();

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvoked: (didPop) {
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
                      decoration: InputDecoration(
                        hintText: l10n.locale == 'vi' ? 'Tìm theo ghi chú, số tiền...' : 'Search note, amount...',
                        border: InputBorder.none,
                        hintStyle: TextStyle(color: Colors.white70),
                      ),
                      style: const TextStyle(color: Colors.white, fontSize: 16),
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
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        setState(() {
                          _isSearching = false;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    )
                  : null,
          actions: _isSelectionMode
              ? [
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: _selectedTransactionIds.isEmpty
                        ? null
                        : () => _showDeleteMultipleDialog(context),
                  ),
                ]
              : [
                  if (!_isSearching)
                    IconButton(
                      icon: const Icon(Icons.search),
                      onPressed: () {
                        setState(() {
                          _isSearching = true;
                        });
                      },
                    ),
                  if (!_isSearching)
                    Stack(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.filter_list),
                          onPressed: () => _showFilterSheet(context, ref),
                        ),
                        if (filterCount > 0)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                filterCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (_isSearching && _searchQuery.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        setState(() {
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
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
              // Apply filters
              final filteredTransactions = _applyFilters(allTransactions);

              // Apply pagination
              final totalItems = filteredTransactions.length;
              final endIndex = (_currentPage * _limit).clamp(0, totalItems);
              final paginatedTransactions = filteredTransactions.take(endIndex).toList();
              _hasMore = endIndex < totalItems;

              final categoryMap = {
                for (var cat in categories) cat.id: cat
              };
              final dayGroups = _groupTransactionsByDay(paginatedTransactions);
              final currency = settingsAsync.value?.currency ?? 'VND';
              final symbol = CurrencyService.getSymbol(currency);
              final theme = Theme.of(context);
              final isDark = theme.brightness == Brightness.dark;

              return Column(
                children: [
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
                  const BannerAdWidget(key: ValueKey('transaction_banner_ad')),
                ],
              );
            },
          );
        },
        ),
        floatingActionButton: FloatingActionButton(
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

  void _showFilterSheet(BuildContext context, WidgetRef ref) {
    final l10n = ref.read(localizationProvider);
    final categoriesAsync = ref.read(categoryProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return categoriesAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (categories) {
              return StatefulBuilder(
                builder: (context, setModalState) {
                  // Filter categories theo type
                  final filteredCategories = _typeFilter != null
                      ? categories.where((cat) => cat.type == _typeFilter).toList()
                      : categories;

                  // Reset categoryFilter nếu không còn trong filtered list
                  if (_categoryFilter != null &&
                      !filteredCategories.any((cat) => cat.id == _categoryFilter)) {
                    _categoryFilter = null;
                  }

                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.filterTransactions,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ],
                        ),
                        const Divider(),
                        Expanded(
                          child: ListView(
                            controller: scrollController,
                            children: [
                              // Time Filter
                              Text(l10n.time, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: _timeFilter,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  DropdownMenuItem(value: 'all', child: Text(l10n.all)),
                                  DropdownMenuItem(value: 'this_month', child: Text(l10n.thisMonth)),
                                  DropdownMenuItem(value: 'last_month', child: Text(l10n.lastMonth)),
                                  DropdownMenuItem(value: 'last_3_months', child: Text(l10n.last3Months)),
                                  DropdownMenuItem(value: 'custom', child: Text(l10n.customRange)),
                                ],
                                onChanged: (value) {
                                  setModalState(() {
                                    _timeFilter = value!;
                                  });
                                },
                              ),

                              // Custom Month Range
                              if (_timeFilter == 'custom') ...[
                                const SizedBox(height: 12),
                                Text(l10n.fromDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: _startMonth,
                                        decoration: InputDecoration(
                                          labelText: l10n.selectMonth,
                                          border: const OutlineInputBorder(),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        items: List.generate(12, (index) {
                                          final monthNum = index + 1;
                                          return DropdownMenuItem(
                                            value: monthNum,
                                            child: Text(l10n.getMonthName(monthNum)),
                                          );
                                        }),
                                        onChanged: (value) {
                                          setModalState(() {
                                            _startMonth = value;
                                            if (_startMonth != null && _startYear != null) {
                                              _startDate = DateTime(_startYear!, _startMonth!, 1);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: _startYear,
                                        decoration: InputDecoration(
                                          labelText: l10n.selectYear,
                                          border: const OutlineInputBorder(),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        items: List.generate(10, (index) {
                                          final year = DateTime.now().year - index;
                                          return DropdownMenuItem(
                                            value: year,
                                            child: Text(year.toString()),
                                          );
                                        }),
                                        onChanged: (value) {
                                          setModalState(() {
                                            _startYear = value;
                                            if (_startMonth != null && _startYear != null) {
                                              _startDate = DateTime(_startYear!, _startMonth!, 1);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(l10n.toDate, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: _endMonth,
                                        decoration: InputDecoration(
                                          labelText: l10n.selectMonth,
                                          border: const OutlineInputBorder(),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        items: List.generate(12, (index) {
                                          final monthNum = index + 1;
                                          return DropdownMenuItem(
                                            value: monthNum,
                                            child: Text(l10n.getMonthName(monthNum)),
                                          );
                                        }),
                                        onChanged: (value) {
                                          setModalState(() {
                                            _endMonth = value;
                                            if (_endMonth != null && _endYear != null) {
                                              // Set to last day of month
                                              final nextMonth = _endMonth! < 12 ? _endMonth! + 1 : 1;
                                              final nextYear = _endMonth! < 12 ? _endYear! : _endYear! + 1;
                                              _endDate = DateTime(nextYear, nextMonth, 1).subtract(const Duration(days: 1));
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: DropdownButtonFormField<int>(
                                        value: _endYear,
                                        decoration: InputDecoration(
                                          labelText: l10n.selectYear,
                                          border: const OutlineInputBorder(),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        ),
                                        items: List.generate(10, (index) {
                                          final year = DateTime.now().year - index;
                                          return DropdownMenuItem(
                                            value: year,
                                            child: Text(year.toString()),
                                          );
                                        }),
                                        onChanged: (value) {
                                          setModalState(() {
                                            _endYear = value;
                                            if (_endMonth != null && _endYear != null) {
                                              // Set to last day of month
                                              final nextMonth = _endMonth! < 12 ? _endMonth! + 1 : 1;
                                              final nextYear = _endMonth! < 12 ? _endYear! : _endYear! + 1;
                                              _endDate = DateTime(nextYear, nextMonth, 1).subtract(const Duration(days: 1));
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ],

                              const SizedBox(height: 20),

                              // Type Filter
                              Text(l10n.type, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String?>(
                                value: _typeFilter,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  DropdownMenuItem(value: null, child: Text(l10n.allTypes)),
                                  DropdownMenuItem(value: 'income', child: Text(l10n.income)),
                                  DropdownMenuItem(value: 'expense', child: Text(l10n.expense)),
                                ],
                                onChanged: (value) {
                                  setModalState(() {
                                    _typeFilter = value;
                                    // Reset category filter khi đổi type
                                    if (_categoryFilter != null) {
                                      final newFilteredCategories = value != null
                                          ? categories.where((cat) => cat.type == value).toList()
                                          : categories;
                                      if (!newFilteredCategories.any((cat) => cat.id == _categoryFilter)) {
                                        _categoryFilter = null;
                                      }
                                    }
                                  });
                                },
                              ),

                              const SizedBox(height: 20),

                              // Category Filter
                              Text(l10n.category, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String?>(
                                value: _categoryFilter,
                                decoration: InputDecoration(
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: [
                                  DropdownMenuItem(value: null, child: Text(l10n.allCategories)),
                                  ...filteredCategories.map((cat) {
                                    final displayName = l10n.translateCategoryName(cat.id, cat.name);

                                    // Get icon and color
                                    final iconData = CategoryIconData.getIcon(cat.icon) ??
                                        (cat.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward);

                                    Color backgroundColor;
                                    if (cat.color != null && cat.color!.isNotEmpty) {
                                      try {
                                        backgroundColor = Color(int.parse(cat.color!.substring(1), radix: 16) + 0xFF000000);
                                      } catch (e) {
                                        backgroundColor = cat.type == 'income' ? Colors.green : Colors.red;
                                      }
                                    } else {
                                      backgroundColor = cat.type == 'income' ? Colors.green : Colors.red;
                                    }

                                    final iconColor = ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.light
                                        ? Colors.black
                                        : Colors.white;

                                    return DropdownMenuItem(
                                      value: cat.id,
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 32,
                                            height: 32,
                                            decoration: BoxDecoration(
                                              color: backgroundColor,
                                              shape: BoxShape.circle,
                                            ),
                                            child: Icon(
                                              iconData,
                                              color: iconColor,
                                              size: 16,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Text(displayName),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (value) {
                                  setModalState(() {
                                    _categoryFilter = value;
                                  });
                                },
                              ),

                              const SizedBox(height: 20),

                              // Amount Range
                              Text(l10n.amountRange, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        labelText: l10n.minAmount,
                                        border: const OutlineInputBorder(),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setModalState(() {
                                          _minAmount = double.tryParse(value.replaceAll(',', ''));
                                        });
                                      },
                                      controller: TextEditingController(
                                        text: _minAmount?.toStringAsFixed(0) ?? '',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: TextField(
                                      decoration: InputDecoration(
                                        labelText: l10n.maxAmount,
                                        border: const OutlineInputBorder(),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        setModalState(() {
                                          _maxAmount = double.tryParse(value.replaceAll(',', ''));
                                        });
                                      },
                                      controller: TextEditingController(
                                        text: _maxAmount?.toStringAsFixed(0) ?? '',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Action Buttons
                        SafeArea(
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setModalState(() {
                                      _timeFilter = 'all';
                                      _typeFilter = null;
                                      _categoryFilter = null;
                                      _minAmount = null;
                                      _maxAmount = null;
                                      _startDate = null;
                                      _endDate = null;
                                      _startMonth = null;
                                      _startYear = null;
                                      _endMonth = null;
                                      _endYear = null;
                                      _currentPage = 1;
                                    });
                                    setState(() {});
                                    Navigator.pop(context);
                                  },
                                  child: Text(l10n.clearAll),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      _currentPage = 1;
                                    });
                                    Navigator.pop(context);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(l10n.apply),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
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
    final l10n = ref.read(localizationProvider);

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(l10n.edit),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, ref, transaction);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _showDeleteDialog(context, ref, transaction);
              },
            ),
            ListTile(
              leading: const Icon(Icons.check_box),
              title: Text(l10n.selectMultiple),
              onTap: () {
                Navigator.pop(context);
                setState(() {
                  _isSelectionMode = true;
                  _selectedTransactionIds.add(transaction.id);
                });
              },
            ),
          ],
        ),
      ),
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
}
