import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/transaction_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/category_provider.dart';
import '../providers/loan_provider.dart';
import '../models/transaction.dart';
import '../models/category.dart';
import '../models/loan_contact.dart';
import '../utils/icon_data.dart';
import '../services/currency_service.dart';
import '../services/rewarded_ad_service.dart';
import '../config/ads_config.dart';
import '../providers/ad_free_provider.dart';
import '../widgets/banner_ad_widget.dart';
import 'transaction_form_screen.dart';
import 'home_screen.dart';
import 'settings_screen.dart';
import '../widgets/voice_record_sheet.dart';
import '../widgets/dashboard/quick_access_hub.dart';

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
    if (AdsConfig.adsEnabled) {
      RewardedAdService.loadRewardedAd();
    }
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
      return tx.transactionDate.year == _selectedYear &&
             tx.transactionDate.month == _selectedMonth;
    }).toList();
  }

  List<int> _getAvailableYears(List<Transaction> transactions) {
    if (transactions.isEmpty) return [DateTime.now().year];

    final years = transactions.map((tx) => tx.transactionDate.year).toSet().toList();
    years.sort();
    return years;
  }

  List<int> _getAvailableMonths(List<Transaction> transactions, int year) {
    if (transactions.isEmpty) return [DateTime.now().month];

    final months = transactions
        .where((tx) => tx.transactionDate.year == year)
        .map((tx) => tx.transactionDate.month)
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

  Widget _buildAdIcon(bool isAdFree) {
    if (isAdFree) {
      // Ad-free: vòng tròn + "AD" + gạch chéo (màu xanh)
      return Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.green, width: 2),
            ),
            child: const Center(
              child: Text(
                'AD',
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ),
          ),
          const Icon(
            Icons.block,
            color: Colors.green,
            size: 32,
          ),
        ],
      );
    } else {
      // Có ads: vòng tròn + "AD" (màu xám)
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey[700]!, width: 2),
        ),
        child: Center(
          child: Text(
            'AD',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final loansAsync = ref.watch(loanProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.dashboard),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (AdsConfig.adsEnabled)
            Consumer(
              builder: (context, ref, child) {
                final isAdFree = ref.watch(adFreeProvider);
                return IconButton(
                  icon: _buildAdIcon(isAdFree),
                  tooltip: isAdFree ? l10n.adFreeActive : l10n.watchAdRemoveAds,
                  onPressed: () => _showRewardedAdDialog(context, ref),
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
                  return loansAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text('Error: $error')),
                    data: (loans) {
                      return Column(
                        children: [
                      Expanded(
                        child: SingleChildScrollView(
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
                              const SizedBox(height: 16),
                              _buildLoanSummaryCards(loans, currency, l10n),
                              const SizedBox(height: 24),
                              
                              QuickAccessHub(l10n: l10n),
                              const SizedBox(height: 16),

                              _buildBudgetCard(
                                context,
                                budgetUsed,
                                budget,
                                budgetPercent,
                                currency,
                                l10n,
                              ),
                              const SizedBox(height: 16),

                              // Category Budgets Progress
                              _buildCategoryBudgetsWidget(
                                transactions,
                                categories,
                                currency,
                                l10n,
                              ),
                              const SizedBox(height: 24),

                              // Recent Transactions (filtered by selected month)
                              _buildRecentTransactions(context, ref, transactions, categories, currency, l10n),
                            ],
                          ),
                        ),
                      ),
                      // Banner Ad - sticky at bottom
                      const BannerAdWidget(key: ValueKey('dashboard_banner_ad')),
                    ],
                  );
                    },
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const TransactionFormScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoanSummaryCards(List<LoanContact> loans, String currency, dynamic l10n) {
    double totalBorrow = 0;
    double totalLend = 0;
    for (var l in loans) {
      if (l.type == 'borrowed') totalBorrow += l.remainingAmount;
      if (l.type == 'lent') totalLend += l.remainingAmount;
    }
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            l10n.locale == 'vi' ? 'Nợ' : 'Borrow',
            totalBorrow,
            currency,
            Colors.amber,
            Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            l10n.locale == 'vi' ? 'Cho vay' : 'Lend',
            totalLend,
            currency,
            Colors.blue,
            Icons.account_balance_wallet_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildLoanPieChartCard({
    required String title,
    required String type,
    required List<LoanContact> loans,
    required String currency,
    required dynamic l10n,
  }) {
    final filteredLoans = loans.where((l) => l.type == type && l.remainingAmount > 0).toList();
    if (filteredLoans.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Text(l10n.noData, style: TextStyle(color: Colors.grey[600])),
            ],
          ),
        ),
      );
    }
    
    final colors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.amber, Colors.cyan, Colors.indigo];
    
    int colorIndex = 0;
    final total = filteredLoans.fold(0.0, (sum, l) => sum + l.remainingAmount);
    
    final sections = filteredLoans.map((l) {
      final percentage = (l.remainingAmount / total * 100);
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return PieChartSectionData(
        value: l.remainingAmount,
        title: '${percentage.toStringAsFixed(1)}%',
        color: color,
        radius: 60,
        titleStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();
    
    colorIndex = 0;
    final legends = filteredLoans.map((l) {
      final color = colors[colorIndex % colors.length];
      colorIndex++;
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 8),
            Expanded(child: Text(l.contactName, style: const TextStyle(fontSize: 13), overflow: TextOverflow.ellipsis)),
            Text('${_formatAmount(l.remainingAmount, currency)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              SizedBox(
                height: 200,
                child: PieChart(PieChartData(sections: sections, sectionsSpace: 2, centerSpaceRadius: 40)),
              ),
              const SizedBox(height: 16),
              ...legends,
            ],
          ),
        ),
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
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
    BuildContext context,
    double used,
    double budget,
    double percent,
    String currency,
    l10n,
  ) {
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
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            if (budget == 0)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.budgetNotSet,
                    style: TextStyle(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SettingsScreen()),
                      );
                    },
                    icon: const Icon(Icons.settings, size: 18),
                    label: Text(l10n.settings),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ],
              )
            else
              Column(
                children: [
                  LinearProgressIndicator(
                    value: percent / 100,
                    backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                    color: percent >= 100
                        ? Colors.red
                        : (percent >= 80 ? Colors.orange : Colors.green),
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
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        '${_formatAmount(used, currency)} / ${_formatAmount(budget, currency)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetsWidget(
    List<Transaction> transactions,
    List<Category> categories,
    String currency,
    dynamic l10n,
  ) {
    // Lọc ra các category có set budgetLimit > 0
    final budgetCategories = categories.where((c) => c.budgetLimit != null && c.budgetLimit! > 0).toList();
    if (budgetCategories.isEmpty) return const SizedBox.shrink();

    // Tính toán số tiền đã dùng cho mỗi category
    final Map<String, double> categorySpent = {};
    for (var tx in transactions) {
      if (tx.type == 'expense' && tx.categoryId != null) {
        categorySpent[tx.categoryId!] = (categorySpent[tx.categoryId!] ?? 0) + tx.amount;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ngân sách danh mục',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: budgetCategories.map((category) {
                final budget = category.budgetLimit!;
                final spent = categorySpent[category.id] ?? 0;
                final percent = (spent / budget * 100).clamp(0, 100).toDouble();

                Color progressColor = Colors.green;
                if (percent >= 100) {
                  progressColor = Colors.red;
                } else if (percent >= 80) {
                  progressColor = Colors.orange;
                } else if (percent >= 50) {
                  progressColor = Colors.amber;
                }

                IconData? iconData = CategoryIconData.getIcon(category.icon);
                Color iconColor = Colors.grey[600]!;
                if (category.color != null && category.color!.isNotEmpty) {
                  try {
                    String hex = category.color!.replaceAll('#', '');
                    if (hex.length == 6) hex = 'FF' + hex;
                    iconColor = Color(int.parse(hex, radix: 16));
                  } catch (e) {
                    // ignore
                  }
                }

                final displayName = l10n.translateCategoryName(category.id, category.name);

                return Container(
                  width: 160,
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.2)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(iconData ?? Icons.category, color: iconColor, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_formatAmount(spent, currency)} / ${_formatAmount(budget, currency)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: percent >= 100 ? Colors.red : Colors.grey[600],
                          fontWeight: percent >= 100 ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: percent / 100,
                          backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                          color: progressColor,
                          minHeight: 4,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              ),
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
    final now = DateTime.now();
    final Map<String, double> monthlyIncome = {};
    final Map<String, double> monthlyExpense = {};
    final List<String> monthKeys = [];
    final List<String> displayNames = [];

    for (int i = _barChartTimeRange - 1; i >= 0; i--) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = '${month.year}-${month.month.toString().padLeft(2, '0')}';
      monthKeys.add(monthKey);
      displayNames.add(l10n.getMonthName(month.month));
      monthlyIncome[monthKey] = 0;
      monthlyExpense[monthKey] = 0;
    }

    for (var tx in transactions) {
      final monthKey = '${tx.transactionDate.year}-${tx.transactionDate.month.toString().padLeft(2, '0')}';
      if (monthlyIncome.containsKey(monthKey)) {
        if (tx.type == 'income') {
          monthlyIncome[monthKey] = (monthlyIncome[monthKey] ?? 0) + tx.amount;
        } else {
          monthlyExpense[monthKey] = (monthlyExpense[monthKey] ?? 0) + tx.amount;
        }
      }
    }

    double maxIncome = 0;
    double maxExpense = 0;
    for (var val in monthlyIncome.values) {
      if (val > maxIncome) maxIncome = val;
    }
    for (var val in monthlyExpense.values) {
      if (val > maxExpense) maxExpense = val;
    }
    if (maxIncome == 0) maxIncome = 1;
    if (maxExpense == 0) maxExpense = 1;

    Widget buildSingleBarChart(String title, Color color, Map<String, double> data, double maxVal) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    maxY: maxVal * 1.2,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            if (value.toInt() >= 0 && value.toInt() < displayNames.length) {
                              return Text(displayNames[value.toInt()], style: const TextStyle(fontSize: 12));
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
                            return Text(_formatShortAmount(value, currency), style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                    barGroups: List.generate(monthKeys.length, (index) {
                      final monthKey = monthKeys[index];
                      final val = data[monthKey] ?? 0;
                      return BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: val,
                            color: color,
                            width: 16,
                            borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), topRight: Radius.circular(4)),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildCarouselWithArrows(
      420,
      [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: buildSingleBarChart(l10n.expense, Colors.red, monthlyExpense, maxExpense),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: buildSingleBarChart(l10n.income, Colors.green, monthlyIncome, maxIncome),
        ),
      ],
      0.95,
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
      final monthKey = '${tx.transactionDate.year}-${tx.transactionDate.month.toString().padLeft(2, '0')}';

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

    double maxExpense = expenseValues.isEmpty ? 0 : expenseValues.reduce((a, b) => a > b ? a : b);
    double maxIncome = incomeValues.isEmpty ? 0 : incomeValues.reduce((a, b) => a > b ? a : b);
    if (maxExpense == 0) maxExpense = 1;
    if (maxIncome == 0) maxIncome = 1;

    Widget buildSingleLineChart(String title, Color color, List<double> values, double maxVal) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    maxY: maxVal * 1.2,
                    minY: 0,
                    lineBarsData: [
                      LineChartBarData(
                        spots: List.generate(displayNames.length, (index) {
                          return FlSpot(index.toDouble(), values[index]);
                        }),
                        isCurved: true,
                        color: color,
                        barWidth: 3,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: color,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: color.withOpacity(0.1),
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
                              return Text(displayNames[value.toInt()], style: const TextStyle(fontSize: 12));
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
                            return Text(_formatShortAmount(value, currency), style: const TextStyle(fontSize: 10));
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: FlGridData(show: true, drawVerticalLine: false),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return _buildCarouselWithArrows(
      420,
      [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: buildSingleLineChart(l10n.expense, Colors.red, expenseValues, maxExpense),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: buildSingleLineChart(l10n.income, Colors.green, incomeValues, maxIncome),
        ),
      ],
      0.95,
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

  Widget _buildPieCharts(List<Transaction> transactions, List<Category> categories, List<LoanContact> loans, String currency, l10n) {
    return _buildCarouselWithArrows(
      420,
      [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildPieChartCard(
            title: l10n.expenseByCategory,
            transactions: transactions.where((t) => t.type == 'expense').toList(),
            categories: categories,
            currency: currency,
            l10n: l10n,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildPieChartCard(
            title: l10n.incomeByCategory,
            transactions: transactions.where((t) => t.type == 'income').toList(),
            categories: categories,
            currency: currency,
            l10n: l10n,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildLoanPieChartCard(
            title: l10n.locale == 'vi' ? 'Nợ theo người' : 'Borrow by contact',
            type: 'borrowed',
            loans: loans,
            currency: currency,
            l10n: l10n,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: _buildLoanPieChartCard(
            title: l10n.locale == 'vi' ? 'Cho vay theo người' : 'Lend by contact',
            type: 'lent',
            loans: loans,
            currency: currency,
            l10n: l10n,
          ),
        ),
      ],
      0.9,
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
      String catId = tx.categoryId ?? 'no_category';
      if (catId != 'no_category') {
        final exists = categories.any((c) => c.id == catId);
        if (!exists) {
          catId = 'no_category';
        }
      }
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
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
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
        child: SingleChildScrollView(
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
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
              ),
            ],
          ),
        ),
      );
    }

    final categoryMap = {
      for (var cat in categories) cat.id: cat
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
              final category = categoryMap[tx.categoryId];
              final categoryName = category != null
                  ? l10n.translateCategoryName(category.id, category.name)
                  : l10n.noCategory;

              // Get icon and color
              final iconData = category != null
                  ? (CategoryIconData.getIcon(category.icon) ??
                      (tx.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward))
                  : (tx.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward);

              Color backgroundColor;
              if (category?.color != null && category!.color!.isNotEmpty) {
                try {
                  backgroundColor = Color(int.parse(category.color!.substring(1), radix: 16) + 0xFF000000);
                } catch (e) {
                  backgroundColor = tx.type == 'income' ? Colors.green : Colors.red;
                }
              } else {
                backgroundColor = tx.type == 'income' ? Colors.green : Colors.red;
              }

              final iconColor = ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.light
                  ? Colors.black
                  : Colors.white;

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  backgroundColor: backgroundColor,
                  radius: 20,
                  child: Icon(
                    iconData,
                    color: iconColor,
                    size: 20,
                  ),
                ),
                title: Text(
                  categoryName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Text(
                  DateFormat('dd/MM/yyyy').format(tx.transactionDate),
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
                onTap: () => _showActionMenu(context, ref, tx),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  String _formatAmount(double amount, String currency) {
    final symbol = CurrencyService.getSymbol(currency);

    // Format based on typical decimal places for currency
    // Most Asian currencies (VND, JPY, KRW, IDR) don't use decimals
    if (amount == amount.toInt()) {
      return '${NumberFormat('#,###').format(amount)} $symbol';
    } else {
      return '${NumberFormat('#,###.##').format(amount)} $symbol';
    }
  }

  Future<void> _showRewardedAdDialog(BuildContext context, WidgetRef ref) async {
    final l10n = ref.read(localizationProvider);

    // Check if already ad-free
    final isAdFree = ref.read(adFreeProvider);
    if (isAdFree) {
      final remaining = await RewardedAdService.getRemainingAdFreeTime();
      if (remaining != null && context.mounted) {
        final hours = remaining.inHours;
        final minutes = remaining.inMinutes.remainder(60);
        final seconds = remaining.inSeconds.remainder(60);

        String timeText;
        if (hours > 0) {
          timeText = '$hours ${l10n.hours} $minutes ${l10n.minutes}';
        } else if (minutes > 0) {
          timeText = '$minutes ${l10n.minutes} $seconds ${l10n.seconds}';
        } else {
          timeText = '$seconds ${l10n.seconds}';
        }

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(l10n.adFreeActive),
            content: Text('${l10n.adFreeStatus} $timeText'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return;
    }

    // Format duration for display
    String durationText;
    if (AdsConfig.adFreeDurationSeconds >= 3600) {
      final hours = AdsConfig.adFreeDurationSeconds ~/ 3600;
      durationText = '$hours ${l10n.hours}';
    } else if (AdsConfig.adFreeDurationSeconds >= 60) {
      final minutes = AdsConfig.adFreeDurationSeconds ~/ 60;
      durationText = '$minutes ${l10n.minutes}';
    } else {
      durationText = '${AdsConfig.adFreeDurationSeconds} ${l10n.seconds}';
    }

    // Show confirmation dialog
    if (context.mounted) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l10n.removeAdsTitle),
          content: Text('${l10n.watchAdPrompt} $durationText?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: Text(l10n.watchAdButton),
            ),
          ],
        ),
      );

      if (confirmed == true && context.mounted) {
        await RewardedAdService.showRewardedAd(
          onUserEarnedReward: () async {
            // Use provider to grant ad-free time
            await ref.read(adFreeProvider.notifier).grantAdFreeTime();
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${l10n.adFreeGranted} $durationText!'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          },
          onAdDismissed: () {
            // Refresh provider status
            ref.read(adFreeProvider.notifier).refresh();
          },
        );
      }
    }
  }

  Widget _buildCarouselWithArrows(double height, List<Widget> children, double viewportFraction) {
    // Start at a very high multiple of children.length to allow infinite scrolling backwards.
    final int initialPage = children.length * 1000;
    final PageController controller = PageController(viewportFraction: viewportFraction, initialPage: initialPage);
    
    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PageView.builder(
            controller: controller,
            itemBuilder: (context, index) {
              return children[index % children.length];
            },
          ),
          Positioned(
            left: 0,
            child: IconButton(
              icon: const Icon(Icons.chevron_left, color: Colors.grey, size: 32),
              onPressed: () {
                if (controller.hasClients) {
                  controller.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                }
              },
            ),
          ),
          Positioned(
            right: 0,
            child: IconButton(
              icon: const Icon(Icons.chevron_right, color: Colors.grey, size: 32),
              onPressed: () {
                if (controller.hasClients) {
                  controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showActionMenu(BuildContext context, WidgetRef ref, Transaction transaction) {
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
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Transaction transaction) {
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

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Transaction transaction) {
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
                await ref.read(transactionProvider.notifier).deleteTransactions([transaction.id]);
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
