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
import '../models/monthly_budget.dart';
import '../services/currency_service.dart';
import '../theme/app_colors.dart';
import '../utils/icon_data.dart';
import '../widgets/month_year_picker_modal.dart';
import '../widgets/category_icon_widget.dart';
import 'category_budget_screen.dart';

class StatisticsScreen extends ConsumerStatefulWidget {
  const StatisticsScreen({super.key});

  @override
  ConsumerState<StatisticsScreen> createState() => _StatisticsScreenState();
}

/// Timeframe options for the overview charts (always monthly grouping).
enum OverviewTimeframe { sixMonths, oneYear, all }

class _StatisticsScreenState extends ConsumerState<StatisticsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _chartScrollController = ScrollController();
  final ScrollController _lineChartScrollController = ScrollController();
  bool _showExpenseCategory = true;
  int _selectedCategoryMonth = DateTime.now().month;
  int _selectedCategoryYear = DateTime.now().year;
  OverviewTimeframe _selectedOverviewTimeframe = OverviewTimeframe.sixMonths;

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

  /// Prepares monthly chart data for both line and bar charts based on [timeframe].
  /// Always groups transactions by month (MM/yy).
  Map<String, dynamic> _prepareOverviewChartData(
    OverviewTimeframe timeframe,
    List<Transaction> transactions,
  ) {
    final now = DateTime.now();
    final Map<String, double> incomeData = {};
    final Map<String, double> expenseData = {};
    final List<String> labels = [];
    final List<String> fullLabels = [];

    int totalMonths;
    if (timeframe == OverviewTimeframe.sixMonths) {
      totalMonths = 6;
    } else if (timeframe == OverviewTimeframe.oneYear) {
      totalMonths = 12;
    } else {
      // all: compute from earliest transaction, at least 6 months
      DateTime earliest = now;
      for (final tx in transactions) {
        if (tx.transactionDate.isBefore(earliest)) earliest = tx.transactionDate;
      }
      totalMonths = (now.year - earliest.year) * 12 + (now.month - earliest.month) + 1;
      if (totalMonths < 6) totalMonths = 6;
    }

    for (int i = totalMonths - 1; i >= 0; i--) {
      final m = DateTime(now.year, now.month - i, 1);
      final key = '${m.year}-${m.month.toString().padLeft(2, '0')}';
      labels.add('${m.month.toString().padLeft(2, '0')}/${m.year.toString().substring(2)}');
      fullLabels.add('Tháng ${m.month.toString().padLeft(2, '0')}/${m.year}');
      incomeData[key] = 0.0;
      expenseData[key] = 0.0;
    }

    for (final tx in transactions) {
      final key = '${tx.transactionDate.year}-${tx.transactionDate.month.toString().padLeft(2, '0')}';
      if (incomeData.containsKey(key)) {
        if (tx.type == 'income') {
          incomeData[key] = incomeData[key]! + tx.amount;
        } else if (tx.type == 'expense') {
          expenseData[key] = expenseData[key]! + tx.amount;
        }
      }
    }

    return {
      'labels': labels,
      'fullLabels': fullLabels,
      'incomeData': incomeData,
      'expenseData': expenseData,
      'totalMonths': totalMonths,
    };
  }

  /// Builds the single unified timeframe selector for both overview charts: 6T | 1N | Tất cả.
  Widget _buildUnifiedTimeframeSelector(dynamic l10n) {
    final options = [
      (OverviewTimeframe.sixMonths, l10n.locale == 'vi' ? '6 Tháng' : '6 Months'),
      (OverviewTimeframe.oneYear, l10n.locale == 'vi' ? '1 Năm' : '1 Year'),
      (OverviewTimeframe.all, l10n.locale == 'vi' ? 'Tất cả' : 'All'),
    ];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[200],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: options.map((entry) {
          final (option, label) = entry;
          final isSelected = _selectedOverviewTimeframe == option;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (_selectedOverviewTimeframe != option) {
                  setState(() => _selectedOverviewTimeframe = option);
                }
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.black : Colors.white)
                        : (isDark ? Colors.grey[400] : Colors.grey[700]),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
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
    _lineChartScrollController.dispose();
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

    for (final tx in transactions) {
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
    }

    final balance = thisMonthIncome - thisMonthExpense;

    // Month over Month calculation
    double momDiff = 0;
    if (lastMonthExpense > 0) {
      momDiff = ((thisMonthExpense - lastMonthExpense) / lastMonthExpense) * 100;
    }

    // === UNIFIED OVERVIEW CHART DATA (MONTHLY) ===
    final chartData = _prepareOverviewChartData(_selectedOverviewTimeframe, transactions);
    final labels = chartData['labels'] as List<String>;
    final fullLabels = chartData['fullLabels'] as List<String>;
    final incomeData = chartData['incomeData'] as Map<String, double>;
    final expenseData = chartData['expenseData'] as Map<String, double>;
    final int totalMonths = chartData['totalMonths'] as int;

    // Line Chart Data: Cashflow = Income - Expense
    final List<double> cashflowValues = [];
    for (int i = 0; i < labels.length; i++) {
      final key = incomeData.keys.elementAt(i);
      cashflowValues.add(incomeData[key]! - expenseData[key]!);
    }

    double minCashflow = cashflowValues.fold(0.0, (a, b) => a < b ? a : b);
    double maxCashflow = cashflowValues.fold(0.0, (a, b) => a > b ? a : b);
    if (minCashflow == maxCashflow) {
      minCashflow -= 1000;
      maxCashflow += 1000;
    } else {
      final pad = (maxCashflow - minCashflow) * 0.15;
      minCashflow -= pad;
      maxCashflow += pad;
    }
    final cashflowRange = maxCashflow - minCashflow;
    final lineLeftInterval = cashflowRange == 0 ? 1000.0 : cashflowRange / 4;

    // Bar Chart Data: Max values for Y axis
    final maxIncome = incomeData.values.fold(0.0, (a, b) => a > b ? a : b);
    final maxExpense = expenseData.values.fold(0.0, (a, b) => a > b ? a : b);
    final maxVal = maxIncome > maxExpense ? maxIncome : maxExpense;
    final barYMax = maxVal == 0 ? 100.0 : maxVal * 1.2;
    final barLeftInterval = barYMax == 0 ? 25.0 : barYMax / 4;

    // Auto-sizing logic:
    // - 6 Months & 1 Year: Always fit exactly on screen (no scroll)
    // - All: Fit on screen if <= 12 months, otherwise horizontally scrollable
    final screenWidth = MediaQuery.of(context).size.width - 64;
    final bool isScrollable = _selectedOverviewTimeframe == OverviewTimeframe.all && totalMonths > 12;

    final double lineChartWidth = isScrollable
        ? (totalMonths * 46.0).clamp(screenWidth, double.infinity)
        : screenWidth;
    final double barChartWidth = isScrollable
        ? (totalMonths * 48.0).clamp(screenWidth, double.infinity)
        : screenWidth;

    // Bar column width adapts to total points for a balanced aesthetic
    final double barRodWidth = totalMonths <= 6
        ? 12.0
        : (totalMonths <= 12 ? 5.5 : 8.0);

    // Auto-scroll to the latest month when scrollable
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (isScrollable) {
        if (_lineChartScrollController.hasClients) {
          _lineChartScrollController.jumpTo(_lineChartScrollController.position.maxScrollExtent);
        }
        if (_chartScrollController.hasClients) {
          _chartScrollController.jumpTo(_chartScrollController.position.maxScrollExtent);
        }
      }
    });

    // Helper to format bottom title labels cleanly
    Widget buildBottomTitle(double value, TitleMeta meta) {
      final idx = value.toInt();
      if (idx >= 0 && idx < labels.length) {
        String displayText = labels[idx];
        if (_selectedOverviewTimeframe == OverviewTimeframe.oneYear) {
          // Format as "T.M" (e.g. T.4, T.12) to stay clean and prevent label collisions
          final parts = labels[idx].split('/');
          if (parts.isNotEmpty) {
            displayText = 'T.${int.tryParse(parts[0]) ?? parts[0]}';
          }
        }
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            displayText,
            style: TextStyle(
              fontSize: _selectedOverviewTimeframe == OverviewTimeframe.oneYear ? 9.5 : 10.0,
              fontWeight: FontWeight.w500,
            ),
          ),
        );
      }
      return const SizedBox.shrink();
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Compact Overview Summary Card
        _buildCompactOverviewSummary(
          balance: balance,
          income: thisMonthIncome,
          expense: thisMonthExpense,
          momDiff: momDiff,
          currency: currency,
          l10n: l10n,
        ),
        const SizedBox(height: 16),

        // Unified Timeframe Selector (6T | 1N | Tất cả)
        _buildUnifiedTimeframeSelector(l10n),
        const SizedBox(height: 16),

        // Line Chart: Biến động dòng tiền (Cash Flow Trend)
        _buildChartCard(
          title: l10n.locale == 'vi' ? 'Biến động Dòng tiền' : 'Cash Flow Trend',
          child: SingleChildScrollView(
            controller: _lineChartScrollController,
            scrollDirection: Axis.horizontal,
            physics: isScrollable ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
            child: SizedBox(
              width: lineChartWidth,
              child: LineChart(
                LineChartData(
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final pointLabel = idx >= 0 && idx < fullLabels.length ? fullLabels[idx] : '';
                          final val = spot.y;
                          final isPos = val >= 0;
                          return LineTooltipItem(
                            '$pointLabel\n${isPos ? '+' : ''}${NumberFormat('#,###').format(val)} ${CurrencyService.getSymbol(currency)}',
                            TextStyle(
                              color: isPos ? Colors.greenAccent : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1.0,
                        getTitlesWidget: buildBottomTitle,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        interval: lineLeftInterval,
                        getTitlesWidget: (value, meta) {
                          return Text(_formatCompact(value), style: const TextStyle(fontSize: 10));
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: minCashflow,
                  maxY: maxCashflow,
                  lineBarsData: [
                    LineChartBarData(
                      spots: List.generate(
                        labels.length,
                        (i) => FlSpot(i.toDouble(), cashflowValues[i]),
                      ),
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: const Color(0xFF0EA5E9),
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          final val = spot.y;
                          return FlDotCirclePainter(
                            radius: totalMonths > 12 ? 3.5 : 4.0,
                            color: val >= 0 ? Colors.green : Colors.red,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            const Color(0xFF0EA5E9).withValues(alpha: 0.25),
                            const Color(0xFF0EA5E9).withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          bottomLegend: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  color: Color(0xFF0EA5E9),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                l10n.locale == 'vi' ? 'Dòng tiền ròng (Thu - Chi)' : 'Net Cashflow (Income - Expense)',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Bar Chart: Tổng Thu & Chi (always aligned with the unified timeframe)
        _buildChartCard(
          title: l10n.locale == 'vi' ? 'Tổng Thu & Chi' : 'Income & Expense',
          child: SingleChildScrollView(
            controller: _chartScrollController,
            scrollDirection: Axis.horizontal,
            physics: isScrollable ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
            child: SizedBox(
              width: barChartWidth,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: barYMax,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final monthLabel = groupIndex >= 0 && groupIndex < fullLabels.length
                            ? fullLabels[groupIndex]
                            : '';
                        final isIncome = rodIndex == 0;
                        final typeLabel = isIncome
                            ? (l10n.locale == 'vi' ? 'Thu' : 'Income')
                            : (l10n.locale == 'vi' ? 'Chi' : 'Expense');
                        final valStr = '${NumberFormat('#,###').format(rod.toY)} ${CurrencyService.getSymbol(currency)}';
                        return BarTooltipItem(
                          '$monthLabel\n$typeLabel: $valStr',
                          TextStyle(
                            color: isIncome ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1.0,
                        getTitlesWidget: buildBottomTitle,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52,
                        interval: barLeftInterval,
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
                          width: barRodWidth,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        BarChartRodData(
                          toY: expenseData[key]!,
                          color: Colors.red,
                          width: barRodWidth,
                          borderRadius: BorderRadius.circular(3),
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
    required double momDiff,
    required String currency,
    required dynamic l10n,
  }) {

    final bool isPositive = balance >= 0;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final savingsRate = income > 0 ? ((balance / income) * 100).clamp(-100.0, 100.0) : 0.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.withValues(alpha: isDark ? 0.25 : 0.15)),
      ),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Row 1: Net Balance + MoM badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.locale == 'vi' ? 'Dòng tiền ròng (Tháng này)' : 'Net Cashflow (This Month)',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodySmall?.color,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          balance >= 0
                              ? '+${NumberFormat('#,###').format(balance)} ${CurrencyService.getSymbol(currency)}'
                              : '-${NumberFormat('#,###').format(balance.abs())} ${CurrencyService.getSymbol(currency)}',
                          style: TextStyle(
                            fontSize: 22,
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
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: (momDiff > 0 ? Colors.red : Colors.green).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        momDiff > 0 ? Icons.trending_up : Icons.trending_down,
                        size: 15,
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
            const SizedBox(height: 14),
            Divider(height: 1, color: Colors.grey.withValues(alpha: 0.15)),
            const SizedBox(height: 14),
            // Row 2: 3 mini stats (Thu nhập, Chi tiêu, Tiết kiệm)
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
                Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.2)),
                Expanded(
                  child: _buildMiniStat(
                    l10n.expense,
                    expense,
                    Colors.red,
                    currency,
                  ),
                ),
                Container(width: 1, height: 32, color: Colors.grey.withValues(alpha: 0.2)),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        l10n.locale == 'vi' ? 'Tiết kiệm' : 'Savings Rate',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.textTheme.bodySmall?.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${savingsRate >= 0 ? '+' : ''}${savingsRate.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: savingsRate >= 0 ? const Color(0xFF0EA5E9) : Colors.red,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
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
          '${NumberFormat('#,###').format(amount)} ${CurrencyService.getSymbol(currency)}',
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
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          ),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (summary) {
            final double totalBudget = summary.totalBudget;
            final double totalSpent = summary.totalSpent;
            final double remaining = summary.remaining;
            final double percent = summary.percentageUsed.clamp(0.0, 1.0);
            final budgetedCats = categories
                .where((c) => c.type == 'expense' && (summary.categoryStatuses[c.id]?.hasBudget ?? false))
                .toList();

            Color progressColor = Colors.green;
            if (summary.isOverBudget) {
              progressColor = Colors.red;
            } else if (percent >= 0.8) {
              progressColor = Colors.orange;
            }

            final isDark = Theme.of(context).brightness == Brightness.dark;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Total Budget Card (matching CategoryBudgetScreen design, read-only)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.15 : 0.06),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: isDark ? 0.3 : 0.15),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.totalMonthlyBudget,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).textTheme.bodySmall?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          totalBudget > 0
                              ? '${CurrencyService.getSymbol(currency)} ${NumberFormat('#,###').format(totalBudget)}'
                              : (l10n.locale == 'vi'
                                  ? 'Chưa đặt ngân sách tổng'
                                  : 'Total budget not set'),
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: totalBudget > 0
                                ? (isDark ? Colors.white : AppColors.primary)
                                : Colors.grey,
                          ),
                        ),
                      ),
                      if (totalBudget > 0) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent,
                            backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                            color: progressColor,
                            minHeight: 8,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '${l10n.locale == 'vi' ? 'Đã chi' : 'Spent'}: ${NumberFormat('#,###').format(totalSpent)} ${CurrencyService.getSymbol(currency)} (${(summary.percentageUsed * 100).toStringAsFixed(1)}%)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: summary.isOverBudget
                                        ? Colors.red
                                        : (isDark ? Colors.grey[400] : Colors.grey[700]),
                                    fontWeight: summary.isOverBudget ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Text(
                                  '${l10n.locale == 'vi' ? 'Còn lại' : 'Remaining'}: ${NumberFormat('#,###').format(remaining)} ${CurrencyService.getSymbol(currency)}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: remaining < 0 ? Colors.red : Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // 2. Section Header: Category Budgets + Quick Action
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.locale == 'vi' ? 'Ngân sách từng danh mục' : 'Category Budgets',
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const CategoryBudgetScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.tune_rounded, size: 16),
                      label: Text(
                        l10n.locale == 'vi' ? 'Quản lý' : 'Manage',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // 3. Category Budgets List (only configured budgets)
                if (budgetedCats.isEmpty)
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.withValues(alpha: isDark ? 0.25 : 0.15)),
                    ),
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: 40,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.locale == 'vi'
                                  ? 'Chưa có danh mục nào được đặt hạn mức'
                                  : 'No category budgets configured',
                              style: TextStyle(
                                fontSize: 13,
                                color: Theme.of(context).textTheme.bodySmall?.color,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextButton.icon(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => const CategoryBudgetScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.add, size: 16),
                              label: Text(l10n.locale == 'vi' ? 'Cài đặt ngân sách' : 'Set Budgets'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                else
                  Card(
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey.withValues(alpha: isDark ? 0.25 : 0.15)),
                    ),
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: budgetedCats.length,
                        separatorBuilder: (_, _) => Divider(
                          height: 1,
                          color: Colors.grey.withValues(alpha: isDark ? 0.15 : 0.1),
                        ),
                        itemBuilder: (context, index) {
                          final cat = budgetedCats[index];
                          final status = summary.categoryStatuses[cat.id];
                          return _buildReadOnlyCategoryBudgetTile(cat, status, currency, l10n);
                        },
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildReadOnlyCategoryBudgetTile(
    Category category,
    CategoryBudgetStatus? status,
    String currency,
    dynamic l10n,
  ) {
    final hasBudget = status != null && status.hasBudget;
    final spent = status?.spent ?? 0.0;
    final budgetLimit = status?.budgetLimit ?? 0.0;
    final percent = (status?.percentage ?? 0.0).clamp(0.0, 1.0);

    Color progressColor = Colors.green;
    if (status?.isOverBudget ?? false) {
      progressColor = Colors.red;
    } else if (status?.isNearLimit ?? false) {
      progressColor = Colors.orange;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIconWidget(category: category, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        l10n.translateCategoryName(category.id, category.name),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (hasBudget)
                      Flexible(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            '${NumberFormat('#,###').format(spent)} / ${NumberFormat('#,###').format(budgetLimit)} ${CurrencyService.getSymbol(currency)}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: status.isOverBudget ? FontWeight.bold : FontWeight.normal,
                              color: status.isOverBudget
                                  ? Colors.red
                                  : (isDark ? Colors.grey[400] : Colors.grey[700]),
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        l10n.locale == 'vi' ? 'Chưa đặt hạn mức' : 'No limit set',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                  ],
                ),
                if (hasBudget) ...[
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: percent,
                      backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                      color: progressColor,
                      minHeight: 6,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${(status.percentage * 100).toStringAsFixed(1)}% ${status.isOverBudget ? (l10n.locale == 'vi' ? '(Vượt hạn mức)' : '(Over limit)') : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: status.isOverBudget ? Colors.red : Colors.grey[600],
                      fontWeight: status.isOverBudget ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
        ? (l10n.locale == 'vi' ? 'Nợ' : 'Borrow by contact')
        : (l10n.locale == 'vi' ? 'Cho vay' : 'Lend by contact');
        
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
                Text(
                  '${contact.contactName}: ${NumberFormat('#,###').format(amount)} ${CurrencyService.getSymbol(currency)}',
                  style: const TextStyle(fontSize: 12),
                ),
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
          ?bottomLegend,
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
