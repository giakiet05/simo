import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/loan_provider.dart';
import '../providers/monthly_budget_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/loan_contact.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';
import '../utils/icon_data.dart';
import '../widgets/month_year_picker_modal.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _chartScrollController = ScrollController();
  bool _showExpenseCategory = true;
  int _selectedCategoryMonth = DateTime.now().month;
  int _selectedCategoryYear = DateTime.now().year;

  Widget _buildCustomChip({
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor : (Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200]),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? (Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white) : Theme.of(context).textTheme.bodyMedium?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _chartScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final txAsync = ref.watch(transactionProvider);
    final catAsync = ref.watch(categoryProvider);
    final loanAsync = ref.watch(loanProvider);
    final settings = ref.watch(settingsProvider).value;
    final currency = settings?.currency ?? 'VND';

    if (txAsync.isLoading || catAsync.isLoading || loanAsync.isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.locale == 'vi' ? 'Thống kê' : 'Insights')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final transactions = txAsync.value ?? [];
    final categories = catAsync.value ?? [];
    final loans = loanAsync.value ?? [];

    final monthRange = MonthRange.fromTransactions(transactions);
    final clamped = monthRange.clamp(_selectedCategoryYear, _selectedCategoryMonth);
    _selectedCategoryYear = clamped.year;
    _selectedCategoryMonth = clamped.month;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(l10n.locale == 'vi' ? 'Thống kê chi tiết' : 'Detailed Insights', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).textTheme.titleLarge?.color ?? Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Theme.of(context).colorScheme.primary,
          isScrollable: true,
          tabs: [
            Tab(text: l10n.locale == 'vi' ? 'Tổng quan' : 'Overview'),
            Tab(text: l10n.locale == 'vi' ? 'Danh mục' : 'Categories'),
            Tab(text: l10n.locale == 'vi' ? 'Ngân sách' : 'Budgets'),
            Tab(text: l10n.locale == 'vi' ? 'Sổ nợ' : 'Loans'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(transactions, loans, currency, l10n),
                _buildCategoriesTab(transactions, categories, currency, l10n, monthRange),
                _buildBudgetsTab(transactions, categories, currency, l10n, monthRange),
                _buildLoansTab(loans, currency, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewTab(
    List<Transaction> transactions,
    List<LoanContact> loans,
    String currency,
    dynamic l10n,
  ) {
    // Analytics calculations for current month
    final now = DateTime.now();
    final startOfThisMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

    double thisMonthIncome = 0;
    double thisMonthExpense = 0;
    double lastMonthExpense = 0;
    
    DateTime earliest = now;
    for (var tx in transactions) {
      if (tx.transactionDate.isAfter(startOfThisMonth) && tx.transactionDate.isBefore(startOfNextMonth)) {
        if (tx.type == 'income') {
          thisMonthIncome += tx.amount;
        } else if (tx.type == 'expense') {
          thisMonthExpense += tx.amount;
        }
      } else if (tx.transactionDate.isAfter(startOfLastMonth) && tx.transactionDate.isBefore(startOfThisMonth)) {
        if (tx.type == 'expense') {
          lastMonthExpense += tx.amount;
        }
      }
      if (tx.transactionDate.isBefore(earliest)) {
        earliest = tx.transactionDate;
      }
    }

    final balance = thisMonthIncome - thisMonthExpense;

    double totalBorrow = 0;
    double totalLend = 0;
    for (var l in loans) {
      if (l.type == 'borrowed') totalBorrow += l.remainingAmount;
      if (l.type == 'lent') totalLend += l.remainingAmount;
    }
    
    // Month over Month calculation
    double momDiff = 0;
    if (lastMonthExpense > 0) {
      momDiff = ((thisMonthExpense - lastMonthExpense) / lastMonthExpense) * 100;
    }

    // Calculate dynamic month span from earliest transaction to now (min 6, max 24)
    int totalMonths = (now.year - earliest.year) * 12 + (now.month - earliest.month) + 1;
    if (totalMonths < 6) totalMonths = 6;
    if (totalMonths > 24) totalMonths = 24;

    // Prepare chart data
    final Map<String, double> incomeData = {};
    final Map<String, double> expenseData = {};
    final List<String> labels = [];

    for (int i = totalMonths - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      labels.add('${m.month}/${m.year.toString().substring(2)}');
      incomeData[key] = 0;
      expenseData[key] = 0;
    }

    for (var tx in transactions) {
      final key = '${tx.transactionDate.year}-${tx.transactionDate.month.toString().padLeft(2, '0')}';
      if (incomeData.containsKey(key)) {
        if (tx.type == 'income') {
          incomeData[key] = incomeData[key]! + tx.amount;
        } else if (tx.type == 'expense') {
          expenseData[key] = expenseData[key]! + tx.amount;
        }
      }
    }

    final maxIncome = incomeData.values.fold(0.0, (a, b) => a > b ? a : b);
    final maxExpense = expenseData.values.fold(0.0, (a, b) => a > b ? a : b);
    final maxVal = maxIncome > maxExpense ? maxIncome : maxExpense;
    final yMax = maxVal == 0 ? 100.0 : maxVal * 1.2;

    double chartWidth = labels.length * 64.0;
    if (chartWidth < MediaQuery.of(context).size.width - 64) {
      chartWidth = MediaQuery.of(context).size.width - 64;
    }

    // Scroll to the most recent month initially
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chartScrollController.hasClients) {
        _chartScrollController.jumpTo(_chartScrollController.position.maxScrollExtent);
      }
    });

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Compact Overview Summary Card
        _buildCompactOverviewSummary(
          balance: balance,
          income: thisMonthIncome,
          expense: thisMonthExpense,
          totalBorrow: totalBorrow,
          totalLend: totalLend,
          momDiff: momDiff,
          currency: currency,
          l10n: l10n,
        ),
        const SizedBox(height: 16),

        _buildChartCard(
          title: l10n.locale == 'vi' ? 'Tổng Thu & Chi' : 'Income & Expense',
          child: SingleChildScrollView(
            controller: _chartScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: chartWidth,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: yMax,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < labels.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(labels[value.toInt()], style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(_formatCompact(value), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  barGroups: List.generate(labels.length, (index) {
                    final key = incomeData.keys.elementAt(index);
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: incomeData[key]!,
                          color: Colors.green,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        BarChartRodData(
                          toY: expenseData[key]!,
                          color: Colors.red,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ),
          bottomLegend: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(l10n.locale == 'vi' ? 'Thu nhập' : 'Income', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
              const SizedBox(width: 24),
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(l10n.locale == 'vi' ? 'Chi tiêu' : 'Expense', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCompactOverviewSummary({
    required double balance,
    required double income,
    required double expense,
    required double totalBorrow,
    required double totalLend,
    required double momDiff,
    required String currency,
    required dynamic l10n,
  }) {
    final bool isPositive = balance >= 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: isDark ? 0.25 : 0.15)),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          children: [
            // Row 1: Balance + MoM badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.balance,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          balance >= 0
                              ? '${NumberFormat('#,###').format(balance)} ${CurrencyService.getSymbol(currency)}'
                              : '-${NumberFormat('#,###').format(balance.abs())} ${CurrencyService.getSymbol(currency)}',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isPositive ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (momDiff > 0 ? Colors.red : Colors.green).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        momDiff > 0 ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color: momDiff > 0 ? Colors.red : Colors.green,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        l10n.locale == 'vi'
                            ? (momDiff > 0 ? '+${momDiff.toStringAsFixed(1)}% chi' : '${momDiff.toStringAsFixed(1)}% chi')
                            : (momDiff > 0 ? '+${momDiff.toStringAsFixed(1)}% exp' : '${momDiff.toStringAsFixed(1)}% exp'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: momDiff > 0 ? Colors.red[700] : Colors.green[700],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
            const SizedBox(height: 10),
            // Row 2: 4 mini stat columns (Thu, Chi, Nợ, Cho vay)
            Row(
              children: [
                Expanded(
                  child: _buildMiniStat(
                    l10n.income,
                    income,
                    Colors.green,
                    currency,
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.grey.withValues(alpha: 0.2)),
                Expanded(
                  child: _buildMiniStat(
                    l10n.expense,
                    expense,
                    Colors.red,
                    currency,
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.grey.withValues(alpha: 0.2)),
                Expanded(
                  child: _buildMiniStat(
                    l10n.locale == 'vi' ? 'Nợ' : 'Borrow',
                    totalBorrow,
                    Colors.amber[800]!,
                    currency,
                  ),
                ),
                Container(width: 1, height: 28, color: Colors.grey.withValues(alpha: 0.2)),
                Expanded(
                  child: _buildMiniStat(
                    l10n.locale == 'vi' ? 'Cho vay' : 'Lend',
                    totalLend,
                    Colors.blue,
                    currency,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, double amount, Color color, String currency) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).textTheme.bodySmall?.color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          '${_formatCompact(amount)} ${CurrencyService.getSymbol(currency)}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildCategoriesTab(List<Transaction> transactions, List<Category> categories, String currency, dynamic l10n, MonthRange monthRange) {
    final txType = _showExpenseCategory ? 'expense' : 'income';
    final recentTx = transactions.where((t) {
      return t.type == txType && 
             t.transactionDate.year == _selectedCategoryYear && 
             t.transactionDate.month == _selectedCategoryMonth;
    }).toList();

    final Map<String, double> categoryTotals = {};
    for (var tx in recentTx) {
      final catId = tx.categoryId ?? 'other';
      categoryTotals[catId] = (categoryTotals[catId] ?? 0) + tx.amount;
    }

    final totalAmount = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final sortedEntries = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      Theme.of(context).colorScheme.primary, AppColors.secondary, Colors.red, AppColors.warning,
      Colors.green, AppColors.info, Colors.purple, Colors.pink, Colors.teal, Colors.indigo,
    ];

    return Column(
      children: [
        MonthNavigationBar(
          selectedYear: _selectedCategoryYear,
          selectedMonth: _selectedCategoryMonth,
          canGoPrevious: monthRange.canGoPrevious(_selectedCategoryYear, _selectedCategoryMonth),
          canGoNext: monthRange.canGoNext(_selectedCategoryYear, _selectedCategoryMonth),
          onPrevious: () {
            final prev = monthRange.previous(_selectedCategoryYear, _selectedCategoryMonth);
            setState(() {
              _selectedCategoryYear = prev.year;
              _selectedCategoryMonth = prev.month;
            });
          },
          onNext: () {
            final next = monthRange.next(_selectedCategoryYear, _selectedCategoryMonth);
            setState(() {
              _selectedCategoryYear = next.year;
              _selectedCategoryMonth = next.month;
            });
          },
          onMonthTap: () => _showMonthYearPicker(context, l10n, monthRange),
          l10n: l10n,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCustomChip(
                  label: l10n.locale == 'vi' ? 'Chi tiêu' : 'Expense',
                  isSelected: _showExpenseCategory,
                  selectedColor: Colors.red,
                  onTap: () => setState(() => _showExpenseCategory = true),
                ),
                const SizedBox(width: 16),
                _buildCustomChip(
                  label: l10n.locale == 'vi' ? 'Thu nhập' : 'Income',
                  isSelected: !_showExpenseCategory,
                  selectedColor: Colors.green,
                  onTap: () => setState(() => _showExpenseCategory = false),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: categoryTotals.isEmpty
              ? Center(child: Text(l10n.locale == 'vi' ? 'Không có dữ liệu' : 'No data'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _buildChartCard(
                      title: _showExpenseCategory
                          ? (l10n.locale == 'vi' ? 'Chi tiêu theo danh mục' : 'Expense by Category')
                          : (l10n.locale == 'vi' ? 'Thu nhập theo danh mục' : 'Income by Category'),
                      height: 250,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 50,
                          sections: List.generate(sortedEntries.length, (index) {
                            final amount = sortedEntries[index].value;
                            final pct = amount / totalAmount * 100;
                            return PieChartSectionData(
                              value: amount,
                              title: '${pct.toStringAsFixed(1)}%',
                              color: colors[index % colors.length],
                              radius: 50,
                              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                            );
                          }),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ...List.generate(sortedEntries.length, (index) {
                      final entry = sortedEntries[index];
                      final cat = categories.where((c) => c.id == entry.key).firstOrNull;
                      final catName = cat != null ? l10n.translateCategoryName(cat.id, cat.name) : 'Khác';
                      final iconData = cat != null ? CategoryIconData.getIcon(cat.icon) : Icons.category;
                      final color = colors[index % colors.length];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.withValues(alpha: 0.2),
                          child: Icon(iconData, color: color, size: 20),
                        ),
                        title: Text(catName, style: const TextStyle(fontWeight: FontWeight.w600)),
                        trailing: Text(
                          '${NumberFormat('#,###').format(entry.value)} ${CurrencyService.getSymbol(currency)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      );
                    }),
                  ],
                ),
        ),
      ],
    );
  }

  void _showMonthYearPicker(BuildContext context, dynamic l10n, MonthRange monthRange) {
    showMonthYearPickerModal(
      context,
      l10n,
      currentYear: _selectedCategoryYear,
      currentMonth: _selectedCategoryMonth,
      startYear: monthRange.startYear,
      startMonth: monthRange.startMonth,
      endYear: monthRange.endYear,
      endMonth: monthRange.endMonth,
      onSelected: (year, month) {
        setState(() {
          _selectedCategoryYear = year;
          _selectedCategoryMonth = month;
        });
      },
    );
  }

  Widget _buildBudgetsTab(
    List<Transaction> transactions,
    List<Category> categories,
    String currency,
    dynamic l10n,
    MonthRange monthRange,
  ) {
    final budgetKey = MonthYearKey(_selectedCategoryYear, _selectedCategoryMonth);
    final summaryAsync = ref.watch(monthlyBudgetFamily(budgetKey));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Month Selector Header - centered
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: MonthNavigationBar(
            selectedYear: _selectedCategoryYear,
            selectedMonth: _selectedCategoryMonth,
            canGoPrevious: monthRange.canGoPrevious(_selectedCategoryYear, _selectedCategoryMonth),
            canGoNext: monthRange.canGoNext(_selectedCategoryYear, _selectedCategoryMonth),
            onPrevious: () {
              final prev = monthRange.previous(_selectedCategoryYear, _selectedCategoryMonth);
              setState(() {
                _selectedCategoryYear = prev.year;
                _selectedCategoryMonth = prev.month;
              });
            },
            onNext: () {
              final next = monthRange.next(_selectedCategoryYear, _selectedCategoryMonth);
              setState(() {
                _selectedCategoryYear = next.year;
                _selectedCategoryMonth = next.month;
              });
            },
            onMonthTap: () => _showMonthYearPicker(context, l10n, monthRange),
            l10n: l10n,
          ),
        ),
        const SizedBox(height: 8),
        summaryAsync.when(
          data: (summary) {
            final budgetStatuses = summary.categoryStatuses.values
                .where((s) => s.hasBudget)
                .toList();

            if (budgetStatuses.isEmpty && !summary.hasBudget) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Text(
                    l10n.noBudgetThisMonth,
                    style: const TextStyle(color: Colors.grey),
                  ),
                ),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (summary.hasBudget) ...[
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
                      ),
                    ),
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  l10n.totalMonthlyBudget,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${NumberFormat('#,###').format(summary.totalBudget)} ${CurrencyService.getSymbol(currency)}',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: summary.percentageUsed.clamp(0.0, 1.0),
                              backgroundColor: Theme.of(context).brightness == Brightness.dark
                                  ? Colors.grey[800]
                                  : Colors.grey[200],
                              color: summary.isOverBudget
                                  ? Colors.red
                                  : (summary.percentageUsed >= 0.8 ? Colors.orange : Colors.green),
                              minHeight: 8,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Text(
                                  '${l10n.locale == 'vi' ? 'Đã chi' : 'Spent'}: ${NumberFormat('#,###').format(summary.totalSpent)} ${CurrencyService.getSymbol(currency)} (${(summary.percentageUsed * 100).toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: summary.isOverBudget ? Colors.red : Colors.grey[700],
                                    fontWeight: summary.isOverBudget ? FontWeight.bold : FontWeight.normal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${l10n.locale == 'vi' ? 'Còn' : 'Remaining'}: ${NumberFormat('#,###').format(summary.remaining)} ${CurrencyService.getSymbol(currency)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: summary.remaining < 0 ? Colors.red : Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.end,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (budgetStatuses.isNotEmpty)
                  _buildChartCard(
                    title: l10n.categoryBudgets,
                    height: budgetStatuses.length * 75.0,
                    child: ListView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: budgetStatuses.length,
                      itemBuilder: (context, index) {
                        final status = budgetStatuses[index];
                        final cat = categories
                            .where((c) => c.id == status.categoryId)
                            .firstOrNull;
                        final budget = status.budgetLimit;
                        final spent = status.spent;
                        final percent = (status.percentage).clamp(0.0, 1.0);

                        Color progressColor = Colors.green;
                        if (status.isOverBudget) {
                          progressColor = Colors.red;
                        } else if (status.isNearLimit) {
                          progressColor = Colors.orange;
                        }

                        final catName = cat != null
                            ? l10n.translateCategoryName(cat.id, cat.name)
                            : 'Khác';
                        final iconData =
                            cat != null ? CategoryIconData.getIcon(cat.icon) : Icons.category;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(iconData,
                                      size: 16,
                                      color: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.color),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      catName,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600, fontSize: 13),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_formatCompact(spent)} / ${_formatCompact(budget)} ${CurrencyService.getSymbol(currency)} (${(status.percentage * 100).toStringAsFixed(0)}%)',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: status.isOverBudget
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: status.isOverBudget
                                          ? Colors.red
                                          : Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.color,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: percent,
                                  backgroundColor:
                                      Theme.of(context).brightness == Brightness.dark
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                  color: progressColor,
                                  minHeight: 8,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
        ),
      ],
    );
  }

  Widget _buildLoansTab(List<LoanContact> loans, String currency, dynamic l10n) {
    final borrowedLoans = loans.where((l) => l.type == 'borrowed' && l.remainingAmount > 0).toList();
    final lentLoans = loans.where((l) => l.type == 'lent' && l.remainingAmount > 0).toList();

    if (borrowedLoans.isEmpty && lentLoans.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.account_balance_wallet_outlined,
                size: 64,
                color: Colors.grey.withValues(alpha: 0.5),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.locale == 'vi'
                    ? 'Không có khoản nợ hay cho vay nào cần theo dõi'
                    : 'No active debts or loans',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (borrowedLoans.isNotEmpty) ...[
          _buildLoanPieChart(borrowedLoans, true, currency, l10n),
          const SizedBox(height: 24),
        ],
        if (lentLoans.isNotEmpty) ...[
          _buildLoanPieChart(lentLoans, false, currency, l10n),
        ],
      ],
    );
  }

  Widget _buildLoanPieChart(List<LoanContact> list, bool isBorrowed, String currency, dynamic l10n) {
    final title = isBorrowed
        ? (l10n.locale == 'vi' ? 'Nợ theo người (Đi vay)' : 'Borrow by contact')
        : (l10n.locale == 'vi' ? 'Cho vay theo người' : 'Lend by contact');
        
    final total = list.fold(0.0, (sum, l) => sum + l.remainingAmount);
    final colors = [Colors.red, Colors.orange, Colors.amber, Colors.blue, Colors.purple, Colors.teal];
    
    return _buildChartCard(
      title: title,
      height: 250,
      child: PieChart(
        PieChartData(
          sectionsSpace: 2,
          centerSpaceRadius: 50,
          sections: List.generate(list.length, (index) {
            final amount = list[index].remainingAmount;
            final pct = amount / total * 100;
            return PieChartSectionData(
              value: amount,
              title: '${pct.toStringAsFixed(1)}%',
              color: colors[index % colors.length],
              radius: 50,
              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
            );
          }),
        ),
      ),
      bottomLegend: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: Wrap(
          spacing: 12,
          runSpacing: 8,
          children: List.generate(list.length, (index) {
            final contact = list[index];
            final amount = contact.remainingAmount;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(width: 12, height: 12, color: colors[index % colors.length]),
                const SizedBox(width: 6),
                Text('${contact.contactName}: ${_formatCompact(amount)}${CurrencyService.getSymbol(currency)}', style: const TextStyle(fontSize: 12)),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildChartCard({required String title, required Widget child, double height = 300, Widget? bottomLegend}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          SizedBox(height: height, child: child),
          if (bottomLegend != null) bottomLegend,
        ],
      ),
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}
