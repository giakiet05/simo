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
  bool _showExpenseCategory = true; // Toggle between expense/income in Categories tab

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(l10n.locale == 'vi' ? 'Thống kê chi tiết' : 'Detailed Insights', style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: l10n.locale == 'vi' ? 'Tổng quan' : 'Overview'),
            Tab(text: l10n.locale == 'vi' ? 'Danh mục' : 'Categories'),
            Tab(text: l10n.locale == 'vi' ? 'Sổ nợ' : 'Loans'),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildTimeFilter(l10n),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(transactions, currency, l10n),
                _buildCategoriesTab(transactions, categories, currency, l10n),
                _buildLoansTab(loans, currency, l10n),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter(dynamic l10n) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      color: AppColors.surface,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [3, 6, 12].map((months) {
          final isSelected = _selectedMonths == months;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text('$months ${l10n.locale == 'vi' ? 'tháng' : 'months'}'),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _selectedMonths = months);
              },
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
              labelStyle: TextStyle(
                color: isSelected ? AppColors.primary : Colors.grey[700],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOverviewTab(List<Transaction> transactions, String currency, dynamic l10n) {
    final now = DateTime.now();
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
      final key = '${tx.createdAt.year}-${tx.createdAt.month.toString().padLeft(2, '0')}';
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
          title: l10n.locale == 'vi' ? 'Xu hướng (Trend)' : 'Trend Line',
          child: LineChart(
            LineChartData(
              maxY: yMax,
              minY: 0,
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(labels.length, (index) {
                    final key = incomeData.keys.elementAt(index);
                    return FlSpot(index.toDouble(), incomeData[key]!);
                  }),
                  isCurved: true,
                  color: Colors.green,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
                LineChartBarData(
                  spots: List.generate(labels.length, (index) {
                    final key = expenseData.keys.elementAt(index);
                    return FlSpot(index.toDouble(), expenseData[key]!);
                  }),
                  isCurved: true,
                  color: Colors.red,
                  barWidth: 3,
                  dotData: FlDotData(show: true),
                ),
              ],
              titlesData: FlTitlesData(
                show: true,
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
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
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoriesTab(List<Transaction> transactions, List<Category> categories, String currency, dynamic l10n) {
    final cutoff = DateTime(DateTime.now().year, DateTime.now().month - _selectedMonths + 1, 1);
    final txType = _showExpenseCategory ? 'expense' : 'income';
    final recentTx = transactions.where((t) => t.type == txType && t.createdAt.isAfter(cutoff)).toList();

    final Map<String, double> categoryTotals = {};
    for (var tx in recentTx) {
      final catId = tx.categoryId ?? 'other';
      categoryTotals[catId] = (categoryTotals[catId] ?? 0) + tx.amount;
    }

    final totalAmount = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final sortedEntries = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    final colors = [
      AppColors.primary, AppColors.secondary, Colors.red, AppColors.warning,
      Colors.green, AppColors.info, Colors.purple, Colors.pink, Colors.teal, Colors.indigo,
    ];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ChoiceChip(
                label: Text(l10n.locale == 'vi' ? 'Chi tiêu' : 'Expense'),
                selected: _showExpenseCategory,
                onSelected: (_) => setState(() => _showExpenseCategory = true),
                selectedColor: Colors.red.withValues(alpha: 0.2),
              ),
              const SizedBox(width: 16),
              ChoiceChip(
                label: Text(l10n.locale == 'vi' ? 'Thu nhập' : 'Income'),
                selected: !_showExpenseCategory,
                onSelected: (_) => setState(() => _showExpenseCategory = false),
                selectedColor: Colors.green.withValues(alpha: 0.2),
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
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
