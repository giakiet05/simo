import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/category_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import 'transaction_form_screen.dart';
import 'settings_screen.dart';
import 'home_screen.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  int _barChartTimeRange = 6;
  int _lineChartTimeRange = 6;

  @override
  void initState() {
    super.initState();
    _loadChartTimeRanges();
  }

  Future<void> _loadChartTimeRanges() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _barChartTimeRange = prefs.getInt('bar_chart_time_range') ?? 6;
      _lineChartTimeRange = prefs.getInt('line_chart_time_range') ?? 6;
    });
  }

  Future<void> _saveBarChartTimeRange(int months) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('bar_chart_time_range', months);
  }

  Future<void> _saveLineChartTimeRange(int months) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('line_chart_time_range', months);
  }

  List<Transaction> _filterTransactionsByMonth(List<Transaction> transactions) {
    return transactions.where((tx) {
      return tx.createdAt.year == _selectedYear &&
             tx.createdAt.month == _selectedMonth;
    }).toList();
  }

  List<int> _getAvailableYears(List<Transaction> transactions) {
    if (transactions.isEmpty) return [DateTime.now().year];

    final years = transactions.map((tx) => tx.createdAt.year).toSet().toList();
    years.sort();
    return years;
  }

  List<int> _getAvailableMonths(List<Transaction> transactions, int year) {
    if (transactions.isEmpty) return [DateTime.now().month];

    final months = transactions
        .where((tx) => tx.createdAt.year == year)
        .map((tx) => tx.createdAt.month)
        .toSet()
        .toList();
    months.sort();

    // Nếu là năm hiện tại, thêm tháng hiện tại nếu chưa có
    if (year == DateTime.now().year && !months.contains(DateTime.now().month)) {
      months.add(DateTime.now().month);
      months.sort();
    }

    return months.isEmpty ? [DateTime.now().month] : months;
  }

  String _getMonthName(int month, l10n) {
    return l10n.getMonthName(month);
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: transactionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Error: $error')),
        data: (allTransactions) {
          // Filter transactions by selected month/year
          final transactions = _filterTransactionsByMonth(allTransactions);

          // Get available years and months for dropdowns
          final availableYears = _getAvailableYears(allTransactions);
          final availableMonths = _getAvailableMonths(allTransactions, _selectedYear);

          // Ensure selected values are valid
          if (!availableYears.contains(_selectedYear)) {
            _selectedYear = availableYears.last;
          }
          if (!availableMonths.contains(_selectedMonth)) {
            _selectedMonth = availableMonths.last;
          }

          double totalIncome = 0;
          double totalExpense = 0;

          for (var tx in transactions) {
            if (tx.type == 'income') {
              totalIncome += tx.amount;
            } else {
              totalExpense += tx.amount;
            }
          }

          final balance = totalIncome - totalExpense;

          return settingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => Center(child: Text('Error: $error')),
            data: (settings) {
              final currency = settings.currency;
              final budget = settings.monthlyBudget;
              final budgetUsed = totalExpense;
              final budgetPercent =
                  budget > 0 ? (budgetUsed / budget * 100).clamp(0, 100).toDouble() : 0.0;

              return categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (categories) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Month/Year Selector
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _selectedMonth,
                                decoration: InputDecoration(
                                  labelText: l10n.selectMonth,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: availableMonths.map((month) {
                                  return DropdownMenuItem(
                                    value: month,
                                    child: Text(_getMonthName(month, l10n)),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedMonth = value!;
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: DropdownButtonFormField<int>(
                                value: _selectedYear,
                                decoration: InputDecoration(
                                  labelText: l10n.selectYear,
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                ),
                                items: availableYears.map((year) {
                                  return DropdownMenuItem(
                                    value: year,
                                    child: Text(year.toString()),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    _selectedYear = value!;
                                    // Update available months for new year
                                    final newMonths = _getAvailableMonths(allTransactions, _selectedYear);
                                    if (!newMonths.contains(_selectedMonth)) {
                                      _selectedMonth = newMonths.last;
                                    }
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Balance Card
                        _buildBalanceCard(balance, currency, l10n),
                        const SizedBox(height: 16),

                        // Income & Expense Cards
                        _buildSummaryCards(
                          totalIncome,
                          totalExpense,
                          balance,
                          currency,
                          l10n,
                        ),
                        const SizedBox(height: 24),

                        // Budget Progress
                        _buildBudgetCard(
                          budgetUsed,
                          budget,
                          budgetPercent,
                          currency,
                          l10n,
                        ),
                        const SizedBox(height: 24),

                        // Bar Chart (uses all transactions)
                        _buildBarChart(allTransactions, currency, l10n),
                        const SizedBox(height: 24),

                        // Line Chart (uses all transactions)
                        _buildLineChart(allTransactions, currency, l10n),
                        const SizedBox(height: 24),

                        // Pie Charts (filtered by selected month)
                        _buildPieCharts(transactions, categories, currency, l10n),
                        const SizedBox(height: 24),

                        // Recent Transactions (filtered by selected month)
                        _buildRecentTransactions(context, ref, transactions, categories, currency, l10n),
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

  Widget _buildSummaryCards(
    double income,
    double expense,
    double balance,
    String currency,
    l10n,
  ) {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            l10n.income,
            income,
            currency,
            Colors.green,
            Icons.arrow_downward,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            l10n.expense,
            expense,
            currency,
            Colors.red,
            Icons.arrow_upward,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    double amount,
    String currency,
    Color color,
    IconData icon,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 20),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _formatAmount(amount, currency),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetCard(
    double used,
    double budget,
    double percent,
    String currency,
    l10n,
  ) {
    Color progressColor = Colors.green;
    if (percent >= 80 && percent < 100) {
      progressColor = Colors.orange;
    } else if (percent >= 100) {
      progressColor = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.monthlyBudget,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: Colors.grey[200],
              color: progressColor,
              minHeight: 8,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${percent.toStringAsFixed(1)}${l10n.percentUsed}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  '${_formatAmount(used, currency)} / ${_formatAmount(budget, currency)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[800],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceCard(double balance, String currency, l10n) {
    final isPositive = balance >= 0;
    final color = isPositive ? Colors.green : Colors.red;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.balance,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  balance >= 0
                      ? _formatAmount(balance, currency)
                      : '-${_formatAmount(balance.abs(), currency)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
            Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              size: 48,
              color: color,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<Transaction> transactions, String currency, l10n) {
    // Group transactions by month
    final now = DateTime.now();
    final Map<String, Map<String, double>> monthlyData = {};
    final List<String> monthKeys = [];
    final List<String> displayNames = [];

    for (int i = _barChartTimeRange - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthKeys.add(monthKey);
      displayNames.add(l10n.getMonthName(month.month));
      monthlyData[monthKey] = {'income': 0, 'expense': 0};
    }

    for (var tx in transactions) {
      final monthKey = '${tx.createdAt.year}-${tx.createdAt.month.toString().padLeft(2, '0')}';

      if (monthlyData.containsKey(monthKey)) {
        if (tx.type == 'income') {
          monthlyData[monthKey]!['income'] =
              (monthlyData[monthKey]!['income'] ?? 0) + tx.amount;
        } else {
          monthlyData[monthKey]!['expense'] =
              (monthlyData[monthKey]!['expense'] ?? 0) + tx.amount;
        }
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.incomeVsExpense,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTimeRangeSelector(_barChartTimeRange, (months) async {
              setState(() {
                _barChartTimeRange = months;
              });
              await _saveBarChartTimeRange(months);
            }, l10n),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxValue(monthlyData) * 1.2,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < displayNames.length) {
                            return Text(
                              displayNames[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatShortAmount(value, currency),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                  barGroups: List.generate(monthKeys.length, (index) {
                    final monthKey = monthKeys[index];
                    final income = monthlyData[monthKey]!['income'] ?? 0;
                    final expense = monthlyData[monthKey]!['expense'] ?? 0;

                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: income,
                          color: Colors.green,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                        BarChartRodData(
                          toY: expense,
                          color: Colors.red,
                          width: 12,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, l10n.income),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red, l10n.expense),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLineChart(List<Transaction> transactions, String currency, l10n) {
    // Group income and expenses by month
    final now = DateTime.now();
    final Map<String, double> monthlyExpenses = {};
    final Map<String, double> monthlyIncome = {};
    final List<String> monthKeys = [];
    final List<String> displayNames = [];

    for (int i = _lineChartTimeRange - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthKeys.add(monthKey);
      displayNames.add(l10n.getMonthName(month.month));
      monthlyExpenses[monthKey] = 0;
      monthlyIncome[monthKey] = 0;
    }

    for (var tx in transactions) {
      final monthKey = '${tx.createdAt.year}-${tx.createdAt.month.toString().padLeft(2, '0')}';

      if (monthlyExpenses.containsKey(monthKey)) {
        if (tx.type == 'expense') {
          monthlyExpenses[monthKey] = (monthlyExpenses[monthKey] ?? 0) + tx.amount;
        } else if (tx.type == 'income') {
          monthlyIncome[monthKey] = (monthlyIncome[monthKey] ?? 0) + tx.amount;
        }
      }
    }

    final expenseValues = monthKeys.map((key) => monthlyExpenses[key] ?? 0).toList();
    final incomeValues = monthKeys.map((key) => monthlyIncome[key] ?? 0).toList();

    final maxExpense = expenseValues.isEmpty ? 0 : expenseValues.reduce((a, b) => a > b ? a : b);
    final maxIncome = incomeValues.isEmpty ? 0 : incomeValues.reduce((a, b) => a > b ? a : b);
    final maxValue = maxExpense > maxIncome ? maxExpense : maxIncome;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.spendingTrend,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildTimeRangeSelector(_lineChartTimeRange, (months) async {
              setState(() {
                _lineChartTimeRange = months;
              });
              await _saveLineChartTimeRange(months);
            }, l10n),
            const SizedBox(height: 16),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  maxY: maxValue * 1.2,
                  minY: 0,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(displayNames.length, (index) {
                        return FlSpot(index.toDouble(), expenseValues[index]);
                      }),
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.red,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.red.withOpacity(0.1),
                      ),
                    ),
                    LineChartBarData(
                      spots: List.generate(displayNames.length, (index) {
                        return FlSpot(index.toDouble(), incomeValues[index]);
                      }),
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: Colors.green,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: Colors.green.withOpacity(0.1),
                      ),
                    ),
                  ],
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() >= 0 && value.toInt() < displayNames.length) {
                            return Text(
                              displayNames[value.toInt()],
                              style: const TextStyle(fontSize: 12),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _formatShortAmount(value, currency),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegendItem(Colors.green, l10n.income),
                const SizedBox(width: 16),
                _buildLegendItem(Colors.red, l10n.expense),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  double _getMaxValue(Map<String, Map<String, double>> monthlyData) {
    double max = 0;
    for (var data in monthlyData.values) {
      final income = data['income'] ?? 0;
      final expense = data['expense'] ?? 0;
      if (income > max) max = income;
      if (expense > max) max = expense;
    }
    return max == 0 ? 1 : max;
  }

  String _formatShortAmount(double amount, String currency) {
    if (amount >= 1000000) {
      return '${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return '${(amount / 1000).toStringAsFixed(0)}K';
    }
    return amount.toStringAsFixed(0);
  }

  Widget _buildTimeRangeSelector(int selectedRange, Function(int) onChanged, l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildTimeRangeButton(l10n.threeMonths, 3, selectedRange, onChanged),
        const SizedBox(width: 8),
        _buildTimeRangeButton(l10n.sixMonths, 6, selectedRange, onChanged),
        const SizedBox(width: 8),
        _buildTimeRangeButton(l10n.oneYear, 12, selectedRange, onChanged),
      ],
    );
  }

  Widget _buildTimeRangeButton(String label, int months, int selectedRange, Function(int) onChanged) {
    final isSelected = selectedRange == months;
    return OutlinedButton(
      onPressed: () => onChanged(months),
      style: OutlinedButton.styleFrom(
        backgroundColor: isSelected ? Colors.teal : Colors.white,
        foregroundColor: isSelected ? Colors.white : Colors.teal,
        side: const BorderSide(color: Colors.teal),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Text(label),
    );
  }

  Widget _buildPieCharts(List<Transaction> transactions, List<Category> categories, String currency, l10n) {
    return Column(
      children: [
        // Income Pie Chart
        _buildPieChartCard(
          title: l10n.incomeByCategory,
          transactions: transactions.where((t) => t.type == 'income').toList(),
          categories: categories,
          currency: currency,
          l10n: l10n,
        ),
        const SizedBox(height: 16),
        // Expense Pie Chart
        _buildPieChartCard(
          title: l10n.expenseByCategory,
          transactions: transactions.where((t) => t.type == 'expense').toList(),
          categories: categories,
          currency: currency,
          l10n: l10n,
        ),
      ],
    );
  }

  Widget _buildPieChartCard({
    required String title,
    required List<Transaction> transactions,
    required List<Category> categories,
    required String currency,
    required l10n,
  }) {
    // Group transactions by category
    final Map<String, double> categoryTotals = {};
    for (var tx in transactions) {
      final catId = tx.categoryId ?? 'no_category';
      categoryTotals[catId] = (categoryTotals[catId] ?? 0) + tx.amount;
    }

    if (categoryTotals.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noData,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    // Create pie chart sections
    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
      Colors.cyan,
      Colors.indigo,
    ];

    int colorIndex = 0;
    final sections = categoryTotals.entries.map((entry) {
      final categoryId = entry.key;
      final amount = entry.value;
      final total = categoryTotals.values.reduce((a, b) => a + b);
      final percentage = (amount / total * 100);

      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return PieChartSectionData(
        value: amount,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();

    // Create legend
    colorIndex = 0;
    final legends = categoryTotals.entries.map((entry) {
      final categoryId = entry.key;
      final amount = entry.value;

      String categoryName = l10n.noCategory;
      if (categoryId != 'no_category') {
        try {
          final category = categories.firstWhere((c) => c.id == categoryId);
          categoryName = l10n.translateCategoryName(category.id, category.name);
        } catch (e) {
          // Category not found, use default
        }
      }

      final color = colors[colorIndex % colors.length];
      colorIndex++;

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                categoryName,
                style: const TextStyle(fontSize: 13),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              _formatAmount(amount, currency),
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...legends,
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
    BuildContext context,
    WidgetRef ref,
    List<Transaction> transactions,
    List<Category> categories,
    String currency,
    l10n,
  ) {
    // Get 5 most recent transactions
    final recentTx = transactions.take(5).toList();

    if (recentTx.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                l10n.recentTransactions,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noTransactions,
                style: TextStyle(color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    final categoryMap = {
      for (var cat in categories)
        cat.id: l10n.translateCategoryName(cat.id, cat.name)
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.recentTransactions,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton(
                  onPressed: () {
                    homeScreenKey.currentState?.switchToTransactionsTab();
                  },
                  child: Text(l10n.viewAll),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...recentTx.map((tx) {
              final categoryName = categoryMap[tx.categoryId] ?? l10n.noCategory;
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: tx.type == 'income' ? Colors.green : Colors.red,
                  radius: 20,
                  child: Icon(
                    tx.type == 'income'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                title: Text(
                  categoryName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(tx.createdAt),
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Text(
                  '${tx.type == 'income' ? '+' : '-'}${_formatAmount(tx.amount, currency)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: tx.type == 'income' ? Colors.green : Colors.red,
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount, String currency) {
    if (currency == 'VND') {
      return '${NumberFormat('#,###').format(amount)} đ';
    } else {
      return '\$${NumberFormat('#,###.##').format(amount)}';
    }
  }
}
