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
import 'wallets_screen.dart';
import 'wallet_detail_screen.dart';
import '../widgets/dashboard/dashboard_net_worth_card.dart';
import '../widgets/dashboard/mini_wallet_carousel.dart';
import '../widgets/dashboard/monthly_cashflow_card.dart';
import '../widgets/wallet_transfer_modal.dart';
import '../widgets/wallet_form_modal.dart';
import '../widgets/category_icon_widget.dart';
import '../models/monthly_budget.dart';
import '../providers/monthly_budget_provider.dart';
import '../providers/wallet_provider.dart';
import '../widgets/dashboard/monthly_metrics_grid.dart';
import 'category_budget_screen.dart';
import 'loan_screen.dart';
import 'statistics_screen.dart';
import 'transaction_screen.dart';

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
    final filtered = transactions.where((tx) {
      return tx.transactionDate.year == _selectedYear &&
             tx.transactionDate.month == _selectedMonth;
    }).toList();
    filtered.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
    return filtered;
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

  void _showMonthYearPickerModal(
    dynamic l10n, {
    required int startYear,
    required int startMonth,
    required int endYear,
    required int endMonth,
  }) {
    int tempYear = _selectedYear.clamp(startYear, endYear);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final allowedMonths = <int>[];
            for (int m = 1; m <= 12; m++) {
              final isAfterStart = (tempYear > startYear) ||
                  (tempYear == startYear && m >= startMonth);
              final isBeforeEnd = (tempYear < endYear) ||
                  (tempYear == endYear && m <= endMonth);
              if (isAfterStart && isBeforeEnd) {
                allowedMonths.add(m);
              }
            }

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left),
                          onPressed: tempYear > startYear
                              ? () => setModalState(() => tempYear--)
                              : null,
                        ),
                        Text(
                          tempYear.toString(),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: tempYear < endYear
                              ? () => setModalState(() => tempYear++)
                              : null,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: allowedMonths.length,
                      itemBuilder: (context, index) {
                        final month = allowedMonths[index];
                        final isSelected =
                            month == _selectedMonth && tempYear == _selectedYear;
                        return InkWell(
                          onTap: () {
                            setState(() {
                              _selectedMonth = month;
                              _selectedYear = tempYear;
                            });
                            Navigator.pop(context);
                          },
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : (Theme.of(context).brightness ==
                                          Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              l10n.locale == 'vi'
                                  ? 'Tháng $month'
                                  : 'Month $month',
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.color,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
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
        toolbarHeight: 44,
        title: Text(
          l10n.dashboard,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
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
          final now = DateTime.now();
          final endYear = now.year;
          final endMonth = now.month;

          int startYear = endYear;
          int startMonth = endMonth;

          if (allTransactions.isNotEmpty) {
            DateTime earliest = allTransactions.first.transactionDate;
            for (final tx in allTransactions) {
              if (tx.transactionDate.isBefore(earliest)) {
                earliest = tx.transactionDate;
              }
            }
            startYear = earliest.year;
            startMonth = earliest.month;
            if (startYear > endYear || (startYear == endYear && startMonth > endMonth)) {
              startYear = endYear;
              startMonth = endMonth;
            }
          }

          // Clamp _selectedYear and _selectedMonth within [start, end]
          if (_selectedYear > endYear || (_selectedYear == endYear && _selectedMonth > endMonth)) {
            _selectedYear = endYear;
            _selectedMonth = endMonth;
          } else if (_selectedYear < startYear || (_selectedYear == startYear && _selectedMonth < startMonth)) {
            _selectedYear = endYear;
            _selectedMonth = endMonth;
          }

          final canGoPrevious = (_selectedYear > startYear) ||
              (_selectedYear == startYear && _selectedMonth > startMonth);
          final canGoNext = (_selectedYear < endYear) ||
              (_selectedYear == endYear && _selectedMonth < endMonth);

          // Filter transactions by selected month/year
          final transactions = _filterTransactionsByMonth(allTransactions);

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
              final budgetKey = MonthYearKey(_selectedYear, _selectedMonth);
              final budgetSummaryAsync = ref.watch(monthlyBudgetFamily(budgetKey));

              return categoriesAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Error: $error')),
                data: (categories) {
                  return loansAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stack) => Center(child: Text('Error: $error')),
                    data: (loans) {
                  final walletsAsync = ref.watch(walletProvider);
                  final totalNetWorth = ref.watch(totalNetWorthProvider);
                  final isBalanceHidden = ref.watch(isBalanceHiddenProvider);
                  final allWallets = walletsAsync.value ?? [];

                  return Column(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // ================= TIER 1: GLOBAL NET WORTH & WALLETS =================
                              // 1. Total Net Worth Hero Card
                              DashboardNetWorthCard(
                                netWorth: totalNetWorth,
                                currency: currency,
                                isHidden: isBalanceHidden,
                                onTogglePrivacy: () {
                                  ref.read(isBalanceHiddenProvider.notifier).state =
                                      !isBalanceHidden;
                                },
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const WalletsScreen(),
                                  ),
                                ),
                                l10n: l10n,
                              ),
                              const SizedBox(height: 8),

                              // 2. Mini Wallet Carousel
                              MiniWalletCarousel(
                                wallets: allWallets,
                                currency: currency,
                                isHidden: isBalanceHidden,
                                onWalletTap: (wallet) => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => WalletDetailScreen(
                                      walletId: wallet.id,
                                    ),
                                  ),
                                ),
                                onAddWalletTap: () =>
                                    WalletFormModal.show(context),
                                l10n: l10n,
                              ),
                              const SizedBox(height: 8),
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: Theme.of(context)
                                    .colorScheme
                                    .outline
                                    .withValues(alpha: 0.1),
                              ),
                              const SizedBox(height: 8),

                              // ================= TIER 2: MONTHLY CASH FLOW & BUDGETS =================
                              // Monthly Cashflow Card with embedded Month Navigator
                              MonthlyCashflowCard(
                                netCashflow: balance,
                                currency: currency,
                                isHidden: isBalanceHidden,
                                l10n: l10n,
                                selectedMonth: _selectedMonth,
                                selectedYear: _selectedYear,
                                onPreviousMonth: canGoPrevious
                                    ? () {
                                        setState(() {
                                          if (_selectedMonth > 1) {
                                            _selectedMonth--;
                                          } else {
                                            _selectedMonth = 12;
                                            _selectedYear--;
                                          }
                                        });
                                      }
                                    : null,
                                onNextMonth: canGoNext
                                    ? () {
                                        setState(() {
                                          if (_selectedMonth < 12) {
                                            _selectedMonth++;
                                          } else {
                                            _selectedMonth = 1;
                                            _selectedYear++;
                                          }
                                        });
                                      }
                                    : null,
                                onMonthPickerTap: () =>
                                    _showMonthYearPickerModal(
                                  l10n,
                                  startYear: startYear,
                                  startMonth: startMonth,
                                  endYear: endYear,
                                  endMonth: endMonth,
                                ),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const StatisticsScreen(),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),

                              // 2x2 Monthly Metrics Grid (Thu nhập, Chi tiêu, Cần thu hồi, Nợ phải trả)
                              Builder(
                                builder: (context) {
                                  double totalBorrow = 0;
                                  double totalLend = 0;
                                  for (var l in loans) {
                                    if (l.type == 'borrowed') {
                                      totalBorrow += l.remainingAmount;
                                    }
                                    if (l.type == 'lent') {
                                      totalLend += l.remainingAmount;
                                    }
                                  }

                                  return MonthlyMetricsGrid(
                                    income: totalIncome,
                                    expense: totalExpense,
                                    totalLent: totalLend,
                                    totalBorrowed: totalBorrow,
                                    currency: currency,
                                    isHidden: isBalanceHidden,
                                    l10n: l10n,
                                    onIncomeTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const TransactionScreen(
                                          initialTypeFilter: 'income',
                                        ),
                                      ),
                                    ),
                                    onExpenseTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const TransactionScreen(
                                          initialTypeFilter: 'expense',
                                        ),
                                      ),
                                    ),
                                    onLentTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const LoanScreen(initialTab: 1),
                                      ),
                                    ),
                                    onBorrowedTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const LoanScreen(initialTab: 0),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 16),

                              _buildBudgetCard(
                                context,
                                budgetSummaryAsync.value,
                                currency,
                                l10n,
                              ),
                              const SizedBox(height: 16),

                              // Category Budgets Progress
                              _buildCategoryBudgetsWidget(
                                budgetSummaryAsync.value,
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
        heroTag: 'dashboard_fab',
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
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
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
    MonthlyBudgetSummary? summary,
    String currency,
    dynamic l10n,
  ) {
    final double budget = summary?.totalBudget ?? 0.0;
    final double used = summary?.totalSpent ?? 0.0;
    final double percent = (summary?.percentageUsed ?? 0.0) * 100;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryBudgetScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.locale == 'vi'
                    ? 'Ngân sách $_selectedMonth/$_selectedYear'
                    : 'Budget $_selectedMonth/$_selectedYear',
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
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const CategoryBudgetScreen()),
                        );
                      },
                      icon: const Icon(Icons.add, size: 18),
                      label: Text(l10n.locale == 'vi' ? 'Thiết lập' : 'Set Budget'),
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
                      value: (percent / 100).clamp(0.0, 1.0),
                      backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                      color: percent >= 100
                          ? Colors.red
                          : (percent >= 80 ? Colors.orange : Colors.green),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: (percent >= 100
                                    ? Colors.red
                                    : (percent >= 80
                                        ? Colors.orange
                                        : Colors.green))
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${percent.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: percent >= 100
                                  ? Colors.red
                                  : (percent >= 80
                                      ? Colors.orange
                                      : Colors.green),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${_formatAmount(used, currency)} / ${_formatAmount(budget, currency)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetsWidget(
    MonthlyBudgetSummary? summary,
    List<Category> categories,
    String currency,
    dynamic l10n,
  ) {
    if (summary == null) return const SizedBox.shrink();

    final budgetStatuses = summary.categoryStatuses.values
        .where((s) => s.hasBudget)
        .toList();

    if (budgetStatuses.isEmpty) return const SizedBox.shrink();

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CategoryBudgetScreen()),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.locale == 'vi'
                    ? 'Ngân sách danh mục ($_selectedMonth/$_selectedYear)'
                    : 'Category Budgets ($_selectedMonth/$_selectedYear)',
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
                children: budgetStatuses.map((status) {
                  final category = categories.where((c) => c.id == status.categoryId).firstOrNull;
                  final budget = status.budgetLimit;
                  final spent = status.spent;

                  Color progressColor = Colors.green;
                  if (status.isOverBudget) {
                    progressColor = Colors.red;
                  } else if (status.isNearLimit) {
                    progressColor = Colors.orange;
                  }

                  IconData? iconData = category != null ? CategoryIconData.getIcon(category.icon) : Icons.category;
                  Color iconColor = Colors.grey[600]!;
                  if (category?.color != null && category!.color!.isNotEmpty) {
                    try {
                      String hex = category.color!.replaceAll('#', '');
                      if (hex.length == 6) hex = 'FF$hex';
                      iconColor = Color(int.parse(hex, radix: 16));
                    } catch (e) {
                      // ignore
                    }
                  }

                  final displayName = category != null
                      ? l10n.translateCategoryName(category.id, category.name)
                      : 'Khác';

                  return Container(
                    width: 160,
                    margin: const EdgeInsets.only(right: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${_formatAmount(spent, currency)} / ${_formatAmount(budget, currency)}',
                            style: TextStyle(
                              fontSize: 11,
                              color: status.isOverBudget ? Colors.red : Colors.grey[600],
                              fontWeight: status.isOverBudget ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: (status.percentage).clamp(0.0, 1.0),
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
                          color: color.withValues(alpha: 0.1),
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
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
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
                l10n.locale == 'vi'
                    ? 'Giao dịch gần nhất ($_selectedMonth/$_selectedYear)'
                    : '${l10n.recentTransactions} ($_selectedMonth/$_selectedYear)',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.noTransactions,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
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
                  l10n.locale == 'vi'
                      ? 'Giao dịch gần nhất ($_selectedMonth/$_selectedYear)'
                      : '${l10n.recentTransactions} ($_selectedMonth/$_selectedYear)',
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

              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CategoryIconWidget(
                  category: category,
                  iconName: category == null ? (tx.type == 'income' ? 'attach_money' : 'shopping_cart') : null,
                  size: 40,
                ),
                title: Text(
                  categoryName,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${l10n.txDateShort}: ${DateFormat('dd/MM/yyyy').format(tx.transactionDate)}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '${l10n.createdAtShort}: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(tx.createdAt)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                    Text(
                      '${l10n.updatedAtShort}: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(tx.updatedAt)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: SizedBox(
                  width: 105,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${tx.type == 'income' ? '+' : '-'}${_formatAmount(tx.amount, currency)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: tx.type == 'income' ? Colors.green : Colors.red,
                      ),
                    ),
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
          editWalletId: transaction.walletId,
          editNote: transaction.note,
          editTransactionDate: transaction.transactionDate,
          editCreatedAt: transaction.createdAt,
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
