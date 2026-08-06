import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../providers/category_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/loan_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/loan_contact.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';
import '../utils/icon_data.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedMonths = 6;
  bool _showExpenseCategory = true;

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
                _buildOverviewTab(transactions, currency, l10n),
                _buildCategoriesTab(transactions, categories, currency, l10n),
                _buildBudgetsTab(transactions, categories, currency, l10n),
                _buildLoansTab(loans, currency, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter(dynamic l10n) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [3, 6, 12].map((months) {
          final isSelected = _selectedMonths == months;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: _buildCustomChip(
              label: '$months ${l10n.locale == 'vi' ? 'tháng' : 'months'}',
              isSelected: isSelected,
              selectedColor: Theme.of(context).colorScheme.primary,
              onTap: () => setState(() => _selectedMonths = months),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewTab(List<Transaction> transactions, String currency, dynamic l10n) {
    // Analytics calculations for current month
    final now = DateTime.now();
    final startOfThisMonth = DateTime(now.year, now.month, 1);
    final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
    final startOfNextMonth = DateTime(now.year, now.month + 1, 1);

    double thisMonthExpense = 0;
    double lastMonthExpense = 0;
    double topExpenseThisMonth = 0;
    Set<int> daysSpent = {};
    
    // Day of week spending
    Map<int, double> dowSpending = {1:0, 2:0, 3:0, 4:0, 5:0, 6:0, 7:0}; // Mon-Sun

    for (var tx in transactions) {
      if (tx.type == 'expense') {
        if (tx.transactionDate.isAfter(startOfThisMonth) && tx.transactionDate.isBefore(startOfNextMonth)) {
          thisMonthExpense += tx.amount;
          daysSpent.add(tx.transactionDate.day);
          if (tx.amount > topExpenseThisMonth) topExpenseThisMonth = tx.amount;
        } else if (tx.transactionDate.isAfter(startOfLastMonth) && tx.transactionDate.isBefore(startOfThisMonth)) {
          lastMonthExpense += tx.amount;
        }
        
        // Day of week
        if (tx.transactionDate.isAfter(DateTime(now.year, now.month - _selectedMonths + 1, 1))) {
          dowSpending[tx.transactionDate.weekday] = (dowSpending[tx.transactionDate.weekday] ?? 0) + tx.amount;
        }
      }
    }

    final currentDay = now.day;
    final noSpendDays = currentDay - daysSpent.length;
    final avgDaily = currentDay > 0 ? thisMonthExpense / currentDay : 0.0;
    
    // Month over Month calculation
    double momDiff = 0;
    if (lastMonthExpense > 0) {
      momDiff = ((thisMonthExpense - lastMonthExpense) / lastMonthExpense) * 100;
    }

    // Prepare chart data
    final Map<String, double> incomeData = {};
    final Map<String, double> expenseData = {};
    final List<String> labels = [];

    for (int i = _selectedMonths - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      labels.add('${m.month}/${m.year}');
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

    final maxVal = [...incomeData.values, ...expenseData.values].fold(0.0, (a, b) => a > b ? a : b);
    final yMax = maxVal == 0 ? 100.0 : maxVal * 1.2;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildTimeFilter(l10n),
        // Quick Stats row
        Row(
          children: [
            Expanded(child: _buildMiniStatCard(l10n.locale == 'vi' ? 'Tiêu TB/ngày' : 'Daily Avg', avgDaily, currency, Icons.calendar_today, Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniStatCard(l10n.locale == 'vi' ? 'Món to nhất' : 'Top Expense', topExpenseThisMonth, currency, Icons.trending_down, Colors.red)),
            const SizedBox(width: 12),
            Expanded(child: _buildMiniStatCard(l10n.locale == 'vi' ? 'Ngày 0đ' : 'No-Spend Days', noSpendDays.toDouble(), '', Icons.sentiment_very_satisfied, Colors.green, isAmount: false)),
          ],
        ),
        const SizedBox(height: 16),
        
        // Month over Month
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: momDiff > 0 ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: momDiff > 0 ? Colors.red.withValues(alpha: 0.3) : Colors.green.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(momDiff > 0 ? Icons.warning_amber_rounded : Icons.check_circle_outline, 
                color: momDiff > 0 ? Colors.red : Colors.green),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.locale == 'vi' 
                    ? (momDiff > 0 ? 'Tháng này tiêu nhiều hơn tháng trước ${momDiff.toStringAsFixed(1)}%' : 'Tuyệt vời! Tháng này tiêu ít hơn tháng trước ${momDiff.abs().toStringAsFixed(1)}%')
                    : (momDiff > 0 ? 'Spent ${momDiff.toStringAsFixed(1)}% more than last month' : 'Great! Spent ${momDiff.abs().toStringAsFixed(1)}% less than last month'),
                  style: TextStyle(fontWeight: FontWeight.w600, color: momDiff > 0 ? Colors.red[700] : Colors.green[700]),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        _buildChartCard(
          title: l10n.locale == 'vi' ? 'Tổng Thu & Chi' : 'Income & Expense',
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
          bottomLegend: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(Colors.green, l10n.locale == 'vi' ? 'Thu nhập' : 'Income'),
              const SizedBox(width: 24),
              _buildLegend(Colors.red, l10n.locale == 'vi' ? 'Chi tiêu' : 'Expense'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildChartCard(
          title: l10n.locale == 'vi' ? 'Chi tiêu theo Thứ' : 'Spending by Day of Week',
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final daysVi = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
                      final daysEn = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                      final days = l10n.locale == 'vi' ? daysVi : daysEn;
                      if (value.toInt() >= 0 && value.toInt() < 7) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(days[value.toInt()], style: const TextStyle(fontSize: 10)),
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
              barGroups: List.generate(7, (index) {
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: dowSpending[index + 1]!,
                      color: (index == 5 || index == 6) ? Colors.orange : Theme.of(context).colorScheme.primary,
                      width: 16,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                );
              }),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMiniStatCard(String title, double value, String currency, IconData icon, Color color, {bool isAmount = true}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(title, style: TextStyle(fontSize: 11, color: Theme.of(context).textTheme.bodySmall?.color), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(
            isAmount ? _formatCompact(value) + CurrencyService.getSymbol(currency) : value.toInt().toString(),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab(List<Transaction> transactions, List<Category> categories, String currency, dynamic l10n) {
    final startOfThisMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final txType = _showExpenseCategory ? 'expense' : 'income';
    final recentTx = transactions.where((t) => t.type == txType && t.transactionDate.isAfter(startOfThisMonth)).toList();

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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildBudgetsTab(List<Transaction> transactions, List<Category> categories, String currency, dynamic l10n) {
    // Only current month budget vs actual
    final now = DateTime.now();
    final startOfThisMonth = DateTime(now.year, now.month, 1);

    final budgetCategories = categories.where((c) => c.budgetLimit != null && c.budgetLimit! > 0).toList();
    
    if (budgetCategories.isEmpty) {
      return Center(child: Text(l10n.locale == 'vi' ? 'Bạn chưa đặt ngân sách nào' : 'No budgets set'));
    }

    final Map<String, double> categorySpent = {};
    for (var tx in transactions) {
      if (tx.type == 'expense' && tx.transactionDate.isAfter(startOfThisMonth)) {
        final catId = tx.categoryId ?? 'other';
        categorySpent[catId] = (categorySpent[catId] ?? 0) + tx.amount;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildChartCard(
          title: l10n.locale == 'vi' ? 'Ngân sách vs Thực tế (Tháng này)' : 'Budget vs Actual (This Month)',
          height: budgetCategories.length * 70.0,
          child: ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            itemCount: budgetCategories.length,
            itemBuilder: (context, index) {
              final cat = budgetCategories[index];
              final budget = cat.budgetLimit!;
              final spent = categorySpent[cat.id] ?? 0.0;
              final percent = (spent / budget).clamp(0.0, 1.0);
              
              Color progressColor = Colors.green;
              if (percent >= 1.0) progressColor = Colors.red;
              else if (percent >= 0.8) progressColor = Colors.orange;
              
              final catName = l10n.translateCategoryName(cat.id, cat.name);
              final iconData = CategoryIconData.getIcon(cat.icon) ?? Icons.category;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(iconData, size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
                        const SizedBox(width: 8),
                        Expanded(child: Text(catName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                        Text(
                          '${_formatCompact(spent)} / ${_formatCompact(budget)} ${CurrencyService.getSymbol(currency)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: percent >= 1.0 ? FontWeight.bold : FontWeight.normal,
                            color: percent >= 1.0 ? Colors.red : Theme.of(context).textTheme.bodySmall?.color,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
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
  }

  Widget _buildLoansTab(List<LoanContact> loans, String currency, dynamic l10n) {
    if (loans.isEmpty) {
      return Center(child: Text(l10n.locale == 'vi' ? 'Không có dữ liệu sổ nợ' : 'No loan data'));
    }

    final borrowedLoans = loans.where((l) => l.type == 'borrowed' && l.remainingAmount > 0).toList();
    final lentLoans = loans.where((l) => l.type == 'lent' && l.remainingAmount > 0).toList();

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
            color: Theme.of(context).brightness == Brightness.dark ? Colors.transparent : Colors.black.withOpacity(0.05),
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

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }
}
