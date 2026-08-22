import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/monthly_budget.dart';
import '../providers/settings_provider.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/monthly_budget_provider.dart';
import '../services/currency_service.dart';
import '../widgets/icon_picker_dialog.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/category_icon_widget.dart';

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

  void _previousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear -= 1;
      } else {
        _selectedMonth -= 1;
      }
    });
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear += 1;
      } else {
        _selectedMonth += 1;
      }
    });
  }

  void _showMonthYearPicker(dynamic l10n) {
    int tempYear = _selectedYear;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
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
                          onPressed: () => setModalState(() => tempYear--),
                        ),
                        Text(
                          tempYear.toString(),
                          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: const Icon(Icons.chevron_right),
                          onPressed: () => setModalState(() => tempYear++),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final month = index + 1;
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
                                  : (Theme.of(context).brightness == Brightness.dark
                                      ? Colors.grey[800]
                                      : Colors.grey[200]),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.locale == 'vi'
                                  ? 'T$month'
                                  : DateFormat('MMM').format(DateTime(2020, month)),
                              style: TextStyle(
                                color: isSelected
                                    ? Colors.white
                                    : Theme.of(context).textTheme.bodyMedium?.color,
                                fontWeight:
                                    isSelected ? FontWeight.bold : FontWeight.normal,
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

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final categoryAsync = ref.watch(categoryProvider);
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
          _buildMonthNavigationBar(l10n),
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

  Widget _buildMonthNavigationBar(dynamic l10n) {
    final monthName = l10n.locale == 'vi'
        ? 'Tháng $_selectedMonth/$_selectedYear'
        : '${DateFormat('MMMM').format(DateTime(_selectedYear, _selectedMonth))} $_selectedYear';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed: _previousMonth,
            tooltip: 'Tháng trước',
          ),
          InkWell(
            onTap: () => _showMonthYearPicker(l10n),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Text(
                monthName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _nextMonth,
            tooltip: 'Tháng sau',
          ),
        ],
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
              Row(
                children: [
                  if (!summary.hasBudget)
                    TextButton.icon(
                      onPressed: () async {
                        await ref
                            .read(monthlyBudgetFamily(key).notifier)
                            .copyFromPreviousMonth();
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.copyBudgetSuccess),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.copy, size: 14),
                      label: Text(
                        l10n.locale == 'vi' ? 'Chép tháng trước' : 'Copy Prev',
                        style: const TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                    ),
                  FilledButton.tonal(
                    onPressed: () => _showAddCategoryDialog('expense'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      minimumSize: Size.zero,
                    ),
                    child: Text(l10n.locale == 'vi' ? '+ Thêm' : '+ Add'),
                  ),
                ],
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
                onPressed: () => _showAddCategoryDialog('income'),
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
              child: Text(l10n.locale == 'vi' ? 'Xóa hạn mức' : 'Clear'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text.replaceAll(',', ''));
              if (val != null && val >= 0) {
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

  void _showSetCategoryBudgetDialog(
    Category category,
    MonthYearKey key,
    CategoryBudgetStatus? status,
    dynamic l10n,
    String currency,
  ) {
    final currentAmount = status?.budgetLimit ?? 0.0;
    final controller = TextEditingController(
      text: currentAmount > 0 ? currentAmount.toInt().toString() : '',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(
          '${l10n.locale == 'vi' ? 'Hạn mức' : 'Budget'}: ${l10n.translateCategoryName(category.id, category.name)} ($_selectedMonth/$_selectedYear)',
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
                labelText: l10n.locale == 'vi' ? 'Hạn mức chi tiêu' : 'Spending Limit',
                prefixText: '${CurrencyService.getSymbol(currency)} ',
                border: const OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          if (currentAmount > 0)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              onPressed: () async {
                Navigator.pop(dialogCtx);
                await ref
                    .read(monthlyBudgetFamily(key).notifier)
                    .deleteCategoryBudget(category.id);
              },
              child: Text(l10n.locale == 'vi' ? 'Xóa hạn mức' : 'Clear'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text.replaceAll(',', ''));
              if (val != null && val >= 0) {
                Navigator.pop(dialogCtx);
                await ref
                    .read(monthlyBudgetFamily(key).notifier)
                    .setCategoryBudget(category.id, val);
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
    final settingsAsync = ref.read(settingsProvider);
    final String currency = settingsAsync.value?.currency ?? 'VND';

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (category.type == 'expense' && key != null)
              ListTile(
                leading: const Icon(Icons.account_balance_wallet, color: Colors.teal),
                title: Text(
                  l10n.locale == 'vi'
                      ? 'Đặt hạn mức tháng $_selectedMonth/$_selectedYear'
                      : 'Set budget for $_selectedMonth/$_selectedYear',
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showSetCategoryBudgetDialog(category, key, status, l10n, currency);
                },
              ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(isSystem
                  ? (l10n.locale == 'vi'
                      ? 'Sửa Icon/Màu (Hệ thống)'
                      : 'Edit Icon/Color (System)')
                  : l10n.edit),
              onTap: () {
                Navigator.pop(context);
                _showEditCategoryDialog(category);
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

  void _showAddCategoryDialog(String type) {
    final controller = TextEditingController();
    final budgetController = TextEditingController();
    final l10n = ref.read(localizationProvider);
    String selectedType = type;
    String? selectedIcon;
    String? selectedColor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Text(
                      l10n.addCategory,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: l10n.categoryName,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 14),
                            ),
                            autofocus: true,
                          ),
                          const SizedBox(height: 12),
                          if (selectedType == 'expense') ...[
                            TextField(
                              controller: budgetController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              decoration: InputDecoration(
                                labelText: l10n.locale == 'vi'
                                    ? 'Hạn mức tháng này (Tùy chọn)'
                                    : 'Monthly Budget (Optional)',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                                prefixIcon: const Icon(Icons.account_balance_wallet),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                CategoryIconWidget(
                                  iconName: selectedIcon,
                                  colorHex: selectedColor,
                                  size: 60,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final result = await showDialog<String>(
                                          context: context,
                                          builder: (context) => IconPickerDialog(
                                            selectedIcon: selectedIcon,
                                            categoryType: selectedType,
                                          ),
                                        );
                                        if (result != null) {
                                          setState(() => selectedIcon = result);
                                        }
                                      },
                                      icon: const Icon(Icons.interests),
                                      label: const Text('Icon'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final result = await showDialog<String>(
                                          context: context,
                                          builder: (context) => ColorPickerDialog(
                                            selectedColor: selectedColor,
                                          ),
                                        );
                                        if (result != null) {
                                          setState(() => selectedColor = result);
                                        }
                                      },
                                      icon: const Icon(Icons.color_lens),
                                      label: const Text('Màu'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final name = controller.text.trim();
                            if (name.isEmpty) return;

                            final budgetText = budgetController.text.replaceAll(',', '').trim();
                            final budget = budgetText.isNotEmpty ? double.tryParse(budgetText) : null;

                            Navigator.pop(context);
                            await ref.read(categoryProvider.notifier).createCategory(
                                  name,
                                  selectedType,
                                  icon: selectedIcon,
                                  color: selectedColor,
                                  budgetLimit: budget,
                                );

                            if (budget != null && budget > 0 && selectedType == 'expense') {
                              final key = MonthYearKey(_selectedYear, _selectedMonth);
                              final cats = await ref.read(categoryRepositoryProvider).getAll();
                              final createdCat = cats.where((c) => c.name == name).firstOrNull;
                              if (createdCat != null) {
                                await ref
                                    .read(monthlyBudgetFamily(key).notifier)
                                    .setCategoryBudget(createdCat.id, budget);
                              }
                            }
                          },
                          child: Text(l10n.save),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showEditCategoryDialog(Category category) {
    final controller = TextEditingController(text: category.name);
    final l10n = ref.read(localizationProvider);
    final isSystem = category.id.startsWith('sys_');
    String? selectedIcon = category.icon;
    String? selectedColor = category.color;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 500),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Text(
                      l10n.editCategory,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (!isSystem) ...[
                            TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                labelText: l10n.categoryName,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 14),
                              ),
                              autofocus: true,
                            ),
                            const SizedBox(height: 12),
                          ],
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                CategoryIconWidget(
                                  category: category,
                                  iconName: selectedIcon,
                                  colorHex: selectedColor,
                                  size: 60,
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final result = await showDialog<String>(
                                          context: context,
                                          builder: (context) => IconPickerDialog(
                                            selectedIcon: selectedIcon,
                                            categoryType: category.type,
                                          ),
                                        );
                                        if (result != null) {
                                          setState(() => selectedIcon = result);
                                        }
                                      },
                                      icon: const Icon(Icons.interests),
                                      label: const Text('Icon'),
                                    ),
                                    OutlinedButton.icon(
                                      onPressed: () async {
                                        final result = await showDialog<String>(
                                          context: context,
                                          builder: (context) => ColorPickerDialog(
                                            selectedColor: selectedColor,
                                          ),
                                        );
                                        if (result != null) {
                                          setState(() => selectedColor = result);
                                        }
                                      },
                                      icon: const Icon(Icons.color_lens),
                                      label: const Text('Màu'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(l10n.cancel),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () async {
                            final name = controller.text.trim();
                            if (name.isEmpty && !isSystem) return;

                            Navigator.pop(context);
                            await ref.read(categoryProvider.notifier).updateCategory(
                                  category.id,
                                  isSystem ? category.name : name,
                                  category.type,
                                  icon: selectedIcon,
                                  color: selectedColor,
                                  budgetLimit: category.budgetLimit,
                                );
                          },
                          child: Text(l10n.save),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String clean = newValue.text.replaceAll(',', '');
    final number = int.tryParse(clean);
    if (number == null) return oldValue;

    final formatted = NumberFormat('#,###').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
