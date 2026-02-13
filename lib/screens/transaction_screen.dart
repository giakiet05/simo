import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../utils/icon_data.dart';
import 'transaction_form_screen.dart';

class TransactionScreen extends ConsumerStatefulWidget {
  const TransactionScreen({super.key});

  @override
  ConsumerState<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends ConsumerState<TransactionScreen> {
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
  final Set<String> _selectedTransactionIds = {};

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
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
        return tx.createdAt.year == now.year && tx.createdAt.month == now.month;
      }).toList();
    } else if (_timeFilter == 'last_month') {
      final lastMonth = DateTime(now.year, now.month - 1);
      filtered = filtered.where((tx) {
        return tx.createdAt.year == lastMonth.year && tx.createdAt.month == lastMonth.month;
      }).toList();
    } else if (_timeFilter == 'last_3_months') {
      final threeMonthsAgo = DateTime(now.year, now.month - 3);
      filtered = filtered.where((tx) => tx.createdAt.isAfter(threeMonthsAgo)).toList();
    } else if (_timeFilter == 'custom') {
      if (_startDate != null) {
        filtered = filtered.where((tx) => tx.createdAt.isAfter(_startDate!)).toList();
      }
      if (_endDate != null) {
        filtered = filtered.where((tx) => tx.createdAt.isBefore(_endDate!.add(const Duration(days: 1)))).toList();
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

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    final categoriesAsync = ref.watch(categoryProvider);
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
                            decoration: BoxDecoration(
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

              return Column(
                children: [
                  if (paginatedTransactions.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      color: Colors.blue[50],
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.longPressHint,
                              style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                            ),
                          ),
                        ],
                      ),
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
                      itemCount: paginatedTransactions.length + (_hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == paginatedTransactions.length) {
                          // Loading indicator at bottom
                          return const Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }

                        final transaction = paginatedTransactions[index];
                        final category = categoryMap[transaction.categoryId];
                        final categoryName = category != null
                            ? l10n.translateCategoryName(category.id, category.name)
                            : l10n.noCategory;
                        final isSelected = _selectedTransactionIds.contains(transaction.id);

                        // Check if we need to show month header
                        final showHeader = index == 0 ||
                          (paginatedTransactions[index - 1].createdAt.month != transaction.createdAt.month ||
                           paginatedTransactions[index - 1].createdAt.year != transaction.createdAt.year);

                        // Get icon and color
                        final iconData = category != null
                            ? (CategoryIconData.getIcon(category.icon) ??
                                (transaction.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward))
                            : (transaction.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward);

                        Color backgroundColor;
                        if (category?.color != null && category!.color!.isNotEmpty) {
                          try {
                            backgroundColor = Color(int.parse(category.color!.substring(1), radix: 16) + 0xFF000000);
                          } catch (e) {
                            backgroundColor = transaction.type == 'income' ? Colors.green : Colors.red;
                          }
                        } else {
                          backgroundColor = transaction.type == 'income' ? Colors.green : Colors.red;
                        }

                        final iconColor = ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.light
                            ? Colors.black
                            : Colors.white;

                        final card = Card(
                          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: isSelected ? Colors.blue[50] : null,
                          child: ListTile(
                            leading: _isSelectionMode
                                ? Checkbox(
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
                                  )
                                : CircleAvatar(
                                    backgroundColor: backgroundColor,
                                    child: Icon(
                                      iconData,
                                      color: iconColor,
                                      size: 20,
                                    ),
                                  ),
                            title: Text(
                              categoryName,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm')
                                      .format(transaction.createdAt),
                                  style: const TextStyle(fontSize: 12),
                                ),
                                if (transaction.formula != null && transaction.formula!.isNotEmpty)
                                  Text(
                                    '${l10n.formula}: ${transaction.formula}',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600], fontStyle: FontStyle.italic),
                                  ),
                                if (transaction.note != null && transaction.note!.isNotEmpty)
                                  Text(
                                    transaction.note!,
                                    style: const TextStyle(fontSize: 13),
                                  ),
                              ],
                            ),
                            trailing: Text(
                              '${transaction.type == 'income' ? '+' : '-'}${NumberFormat('#,###').format(transaction.amount)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: transaction.type == 'income'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
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
                                : null,
                            onLongPress: _isSelectionMode
                                ? null
                                : () => _showActionMenu(context, ref, transaction),
                          ),
                        );

                        // Return with header if needed
                        if (showHeader) {
                          final monthNum = transaction.createdAt.month;
                          final year = transaction.createdAt.year;

                          final headerText = l10n.locale == 'vi'
                              ? 'Tháng $monthNum/$year'
                              : '${l10n.getMonthName(monthNum)} $year';

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                margin: const EdgeInsets.only(top: 8),
                                color: Colors.grey[200],
                                child: Text(
                                  headerText,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ),
                              card,
                            ],
                          );
                        } else {
                          return card;
                        }
                      },
                    )
                  ),
                ],
              );
            },
          );
        },
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
          editNote: transaction.note,
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
