import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/monthly_budget.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/monthly_budget_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/transaction_provider.dart';
import '../services/currency_service.dart';
import '../utils/app_constants.dart';
import '../utils/currency_input_formatter.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/category_form_modal.dart';
import '../widgets/category_icon_widget.dart';
import '../widgets/month_year_picker_modal.dart';

class CategoryBudgetScreen extends ConsumerStatefulWidget {
  const CategoryBudgetScreen({super.key});

  @override
  ConsumerState<CategoryBudgetScreen> createState() => _CategoryBudgetScreenState();
}

class _CategoryBudgetScreenState extends ConsumerState<CategoryBudgetScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _previousMonth(MonthRange monthRange) {
    final prev = monthRange.previous(_selectedYear, _selectedMonth);
    setState(() {
      _selectedYear = prev.year;
      _selectedMonth = prev.month;
    });
  }

  void _nextMonth(MonthRange monthRange) {
    final next = monthRange.next(_selectedYear, _selectedMonth);
    setState(() {
      _selectedYear = next.year;
      _selectedMonth = next.month;
    });
  }

  void _showMonthYearPicker(dynamic l10n, MonthRange monthRange) {
    showMonthYearPickerModal(
      context,
      l10n,
      currentYear: _selectedYear,
      currentMonth: _selectedMonth,
      startYear: monthRange.startYear,
      startMonth: monthRange.startMonth,
      endYear: monthRange.endYear,
      endMonth: monthRange.endMonth,
      onSelected: (year, month) {
        setState(() {
          _selectedYear = year;
          _selectedMonth = month;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final categoryAsync = ref.watch(categoryProvider);
    final transactionsAsync = ref.watch(transactionNotifierProvider);
    final transactions = transactionsAsync.value ?? [];
    final monthRange = MonthRange.fromTransactions(transactions);
    final clamped = monthRange.clamp(_selectedYear, _selectedMonth);
    _selectedYear = clamped.year;
    _selectedMonth = clamped.month;

    final budgetKey = MonthYearKey(_selectedYear, _selectedMonth);
    final budgetSummaryAsync = ref.watch(monthlyBudgetFamily(budgetKey));

    final String currency = settingsAsync.value?.currency ?? 'VND';

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.locale == 'vi' ? 'Danh mục & Ngân sách' : 'Categories & Budgets'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: l10n.expense),
            Tab(text: l10n.income),
          ],
        ),
      ),
      body: Column(
        children: [
          // Month navigation bar
          _buildMonthNavigationBar(l10n, monthRange),
          Expanded(
            child: categoryAsync.when(
              data: (categories) {
                final expenseCats =
                    categories.where((c) => c.type == 'expense').toList();
                final incomeCats =
                    categories.where((c) => c.type == 'income').toList();

                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Expense Tab
                    budgetSummaryAsync.when(
                      data: (summary) => _buildExpenseTab(
                          expenseCats, summary, currency, l10n, budgetKey),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Center(child: Text('Error: $e')),
                    ),
                    // Income Tab
                    _buildIncomeTab(incomeCats, currency, l10n),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthNavigationBar(dynamic l10n, MonthRange monthRange) {
    final canGoPrevious = monthRange.canGoPrevious(_selectedYear, _selectedMonth);
    final canGoNext = monthRange.canGoNext(_selectedYear, _selectedMonth);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: MonthNavigationBar(
        selectedYear: _selectedYear,
        selectedMonth: _selectedMonth,
        canGoPrevious: canGoPrevious,
        canGoNext: canGoNext,
        onPrevious: () => _previousMonth(monthRange),
        onNext: () => _nextMonth(monthRange),
        onMonthTap: () => _showMonthYearPicker(l10n, monthRange),
        l10n: l10n,
      ),
    );
  }

  Widget _buildExpenseTab(
    List<Category> expenseCats,
    MonthlyBudgetSummary summary,
    String currency,
    dynamic l10n,
    MonthYearKey key,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: _buildTotalBudgetSection(summary, currency, l10n, key),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.locale == 'vi' ? 'Ngân sách từng danh mục' : 'Category Budgets',
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              FilledButton.tonal(
                onPressed: () => CategoryFormModal.show(
                  context,
                  initialType: 'expense',
                  monthYearKey: key,
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                ),
                child: Text(l10n.locale == 'vi' ? '+ Thêm' : '+ Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: expenseCats.isEmpty
              ? Center(
                  child: Text(l10n.locale == 'vi'
                      ? 'Chưa có danh mục chi tiêu'
                      : 'No expense categories'),
                )
              : ListView.builder(
                  itemCount: expenseCats.length,
                  itemBuilder: (context, index) {
                    final cat = expenseCats[index];
                    final status = summary.categoryStatuses[cat.id];
                    return _buildCategoryTile(cat, status, currency, l10n, key);
                  },
                ),
        ),
        const BannerAdWidget(key: ValueKey('cat_budget_banner_1')),
      ],
    );
  }

  Widget _buildTotalBudgetSection(
    MonthlyBudgetSummary summary,
    String currency,
    dynamic l10n,
    MonthYearKey key,
  ) {
    final double totalBudget = summary.totalBudget;
    final double totalSpent = summary.totalSpent;
    final double remaining = summary.remaining;
    final double percent = summary.percentageUsed.clamp(0.0, 1.0);

    Color progressColor = Colors.green;
    if (summary.isOverBudget) {
      progressColor = Colors.red;
    } else if (percent >= 0.8) {
      progressColor = Colors.orange;
    }

    return InkWell(
      onTap: () => _showSetTotalBudgetDialog(totalBudget, key, l10n, currency),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
        ),
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
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              totalBudget > 0
                  ? '${CurrencyService.getSymbol(currency)} ${NumberFormat('#,###').format(totalBudget)}'
                  : (l10n.locale == 'vi'
                      ? 'Chưa đặt ngân sách tổng'
                      : 'Total budget not set'),
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: totalBudget > 0
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey,
              ),
            ),
            if (totalBudget > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? Colors.grey[800]
                      : Colors.grey[200],
                  color: progressColor,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      '${l10n.locale == 'vi' ? 'Đã chi' : 'Spent'}: ${NumberFormat('#,###').format(totalSpent)} ${CurrencyService.getSymbol(currency)} (${(summary.percentageUsed * 100).toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        color: summary.isOverBudget ? Colors.red : Colors.grey[700],
                        fontWeight:
                            summary.isOverBudget ? FontWeight.bold : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${l10n.locale == 'vi' ? 'Còn lại' : 'Remaining'}: ${NumberFormat('#,###').format(remaining)} ${CurrencyService.getSymbol(currency)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: remaining < 0 ? Colors.red : Colors.green[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                l10n.locale == 'vi'
                    ? 'Chạm để thiết lập ngân sách cho tháng này'
                    : 'Tap to set budget for this month',
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(
    Category category,
    CategoryBudgetStatus? status,
    String currency,
    dynamic l10n,
    MonthYearKey key,
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

    return InkWell(
      onTap: () => _showActionMenu(context, category, key, status),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (hasBudget)
                        Text(
                          '${NumberFormat('#,###').format(spent)} / ${NumberFormat('#,###').format(budgetLimit)} ${CurrencyService.getSymbol(currency)}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: status.isOverBudget
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: status.isOverBudget
                                ? Colors.red
                                : Colors.grey[700],
                          ),
                        )
                      else
                        Text(
                          l10n.locale == 'vi'
                              ? 'Chưa đặt hạn mức'
                              : 'No limit set',
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
                        backgroundColor:
                            Theme.of(context).brightness == Brightness.dark
                                ? Colors.grey[800]
                                : Colors.grey[200],
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
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIncomeTab(List<Category> incomeCats, String currency, dynamic l10n) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.locale == 'vi' ? 'Danh mục thu nhập' : 'Income Categories',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              FilledButton.tonal(
                onPressed: () => CategoryFormModal.show(
                  context,
                  initialType: 'income',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                ),
                child: Text(l10n.locale == 'vi' ? '+ Thêm' : '+ Add'),
              ),
            ],
          ),
        ),
        Expanded(
          child: incomeCats.isEmpty
              ? Center(
                  child: Text(l10n.locale == 'vi'
                      ? 'Chưa có danh mục thu nhập'
                      : 'No income categories'),
                )
              : ListView.builder(
                  itemCount: incomeCats.length,
                  itemBuilder: (context, index) {
                    final cat = incomeCats[index];
                    return InkWell(
                      onTap: () => _showActionMenu(context, cat, null, null),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: CategoryIconWidget(category: cat),
                        title: Text(
                          l10n.translateCategoryName(cat.id, cat.name),
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    );
                  },
                ),
        ),
        const BannerAdWidget(key: ValueKey('cat_budget_banner_2')),
      ],
    );
  }

  void _showSetTotalBudgetDialog(
    double currentBudget,
    MonthYearKey key,
    dynamic l10n,
    String currency,
  ) {
    final controller = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toInt().toString() : '',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          l10n.locale == 'vi'
              ? 'Ngân sách tháng $_selectedMonth/$_selectedYear'
              : 'Budget for $_selectedMonth/$_selectedYear',
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.locale == 'vi' ? 'Số tiền ngân sách' : 'Budget Amount',
                prefixText: '${CurrencyService.getSymbol(currency)} ',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (currentBudget > 0)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await ref.read(monthlyBudgetFamily(key).notifier).deleteTotalBudget();
              },
              child: Text(l10n.locale == 'vi' ? 'Xóa ngân sách' : 'Clear'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text.replaceAll(',', ''));
              if (val != null && val >= 0) {
                if (val > AppConstants.maxAmount) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(AppConstants.maxAmountError(l10n))),
                  );
                  return;
                }
                Navigator.pop(dialogCtx);
                await ref.read(monthlyBudgetFamily(key).notifier).setTotalBudget(val);
              }
            },
            child: Text(l10n.save),
          ),
        ],
      ),
    );
  }

  void _showActionMenu(
    BuildContext context,
    Category category,
    MonthYearKey? key,
    CategoryBudgetStatus? status,
  ) {
    final l10n = ref.read(localizationProvider);
    final isSystem = category.id.startsWith('sys_');

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_note, color: Colors.teal),
              title: Text(
                isSystem
                    ? (l10n.locale == 'vi'
                        ? 'Sửa Icon/Màu & Hạn mức'
                        : 'Edit Icon/Color & Budget')
                    : (l10n.locale == 'vi'
                        ? 'Chỉnh sửa & Hạn mức'
                        : 'Edit & Budget'),
              ),
              subtitle: category.type == 'expense' && key != null
                  ? Text(
                      l10n.locale == 'vi'
                          ? 'Cập nhật thông tin & hạn mức tháng $_selectedMonth/$_selectedYear'
                          : 'Update info & budget for $_selectedMonth/$_selectedYear',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    )
                  : null,
              onTap: () {
                Navigator.pop(context);
                CategoryFormModal.show(
                  context,
                  categoryToEdit: category,
                  initialBudget: status?.budgetLimit ?? category.budgetLimit,
                  monthYearKey: key,
                );
              },
            ),
            if (!isSystem)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(category);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(Category category) {
    final l10n = ref.read(localizationProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCategory),
        content: Text(l10n.deleteCategoryConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(context);
              await ref.read(categoryProvider.notifier).deleteCategory(category.id);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}
