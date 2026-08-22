import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/category.dart';
import '../../models/monthly_budget.dart';
import '../../providers/settings_provider.dart';
import '../../providers/category_provider.dart';
import '../../providers/localization_provider.dart';
import '../../providers/monthly_budget_provider.dart';
import '../../theme/app_colors.dart';
import '../../services/currency_service.dart';
import '../../utils/icon_data.dart';

class BudgetSheet extends ConsumerStatefulWidget {
  const BudgetSheet({super.key});

  @override
  ConsumerState<BudgetSheet> createState() => _BudgetSheetState();
}

class _BudgetSheetState extends ConsumerState<BudgetSheet> {
  final TextEditingController _totalBudgetController = TextEditingController();
  bool _isEditingTotal = false;

  @override
  void dispose() {
    _totalBudgetController.dispose();
    super.dispose();
  }

  void _saveTotalBudget(MonthYearKey key) {
    final val = double.tryParse(_totalBudgetController.text.replaceAll(',', ''));
    if (val != null) {
      ref.read(monthlyBudgetFamily(key).notifier).setTotalBudget(val);
      ref.read(settingsProvider.notifier).updateBudget(val);
    }
    setState(() {
      _isEditingTotal = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final settingsAsync = ref.watch(settingsProvider);
    final categoryAsync = ref.watch(categoryProvider);

    final now = DateTime.now();
    final budgetKey = MonthYearKey(now.year, now.month);
    final summaryAsync = ref.watch(monthlyBudgetFamily(budgetKey));

    final String currency = settingsAsync.value?.currency ?? 'VND';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 24,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            '${l10n.monthlyBudget} (${now.month}/${now.year})',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          summaryAsync.when(
            data: (summary) => _buildTotalBudgetSection(summary, currency, budgetKey),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
          const SizedBox(height: 24),
          Text(
            l10n.categoryBudgets,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: categoryAsync.when(
              data: (categories) {
                final expenseCats = categories.where((c) => c.type == 'expense').toList();
                if (expenseCats.isEmpty) {
                  return Center(
                    child: Text(l10n.locale == 'vi'
                        ? 'Chưa có danh mục chi tiêu'
                        : 'No expense categories'),
                  );
                }

                final summary = summaryAsync.value;

                return ListView.builder(
                  itemCount: expenseCats.length,
                  itemBuilder: (context, index) {
                    final cat = expenseCats[index];
                    final status = summary?.categoryStatuses[cat.id];
                    return _buildCategoryBudgetTile(cat, status, currency, budgetKey);
                  },
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

  Widget _buildTotalBudgetSection(MonthlyBudgetSummary summary, String currency, MonthYearKey key) {
    final double totalBudget = summary.totalBudget;

    if (_isEditingTotal) {
      if (_totalBudgetController.text.isEmpty && totalBudget > 0) {
        _totalBudgetController.text = totalBudget.toInt().toString();
      }

      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _totalBudgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: InputDecoration(
                prefixText: '${CurrencyService.getSymbol(currency)} ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: () => _saveTotalBudget(key),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Icon(Icons.check),
          ),
        ],
      );
    }

    final double percent = summary.percentageUsed.clamp(0.0, 1.0);
    Color progressColor = Colors.green;
    if (summary.isOverBudget) {
      progressColor = Colors.red;
    } else if (percent >= 0.8) {
      progressColor = Colors.orange;
    }

    return InkWell(
      onTap: () {
        if (totalBudget > 0) {
          _totalBudgetController.text = totalBudget.toInt().toString();
        }
        setState(() => _isEditingTotal = true);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              totalBudget > 0
                  ? '${CurrencyService.getSymbol(currency)} ${NumberFormat('#,###').format(totalBudget)}'
                  : (ref.read(localizationProvider).locale == 'vi' ? 'Chưa đặt ngân sách' : 'Not set'),
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: totalBudget > 0 ? Theme.of(context).colorScheme.primary : Colors.grey,
              ),
            ),
            if (totalBudget > 0) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                  color: progressColor,
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Đã chi: ${NumberFormat('#,###').format(summary.totalSpent)} ${CurrencyService.getSymbol(currency)} (${(summary.percentageUsed * 100).toStringAsFixed(1)}%)',
                    style: TextStyle(fontSize: 12, color: summary.isOverBudget ? Colors.red : Colors.grey[700]),
                  ),
                  Text(
                    'Còn: ${NumberFormat('#,###').format(summary.remaining)} ${CurrencyService.getSymbol(currency)}',
                    style: TextStyle(fontSize: 12, color: summary.remaining < 0 ? Colors.red : Colors.green[700], fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                ref.read(localizationProvider).locale == 'vi' ? 'Chạm để sửa ngân sách' : 'Tap to edit',
                style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBudgetTile(Category category, CategoryBudgetStatus? status, String currency, MonthYearKey key) {
    final hasBudget = status != null && status.hasBudget;
    final budgetLimit = status?.budgetLimit ?? 0.0;
    final spent = status?.spent ?? 0.0;
    final iconData = CategoryIconData.getIcon(category.icon) ?? Icons.category;

    Color backgroundColor = AppColors.warning;
    if (category.color != null && category.color!.isNotEmpty) {
      try {
        String hex = category.color!.replaceAll('#', '');
        if (hex.length == 6) hex = 'FF$hex';
        backgroundColor = Color(int.parse(hex, radix: 16));
      } catch (e) {
        backgroundColor = AppColors.warning;
      }
    }

    final l10n = ref.read(localizationProvider);
    final percent = (status?.percentage ?? 0.0).clamp(0.0, 1.0);

    return InkWell(
      onTap: () => _showEditBudgetDialog(category, budgetLimit, key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: backgroundColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(iconData, color: backgroundColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.translateCategoryName(category.id, category.name),
                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                      ),
                      Text(
                        hasBudget
                            ? '${NumberFormat('#,###').format(budgetLimit)} ${CurrencyService.getSymbol(currency)}'
                            : (l10n.locale == 'vi' ? 'Chưa đặt' : 'Not set'),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: hasBudget ? Theme.of(context).colorScheme.primary : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                  if (hasBudget) ...[
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: percent,
                        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[200],
                        color: status.isOverBudget ? Colors.red : Colors.green,
                        minHeight: 6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Đã chi: ${NumberFormat('#,###').format(spent)} (${(status.percentage * 100).toStringAsFixed(1)}%)',
                      style: TextStyle(fontSize: 11, color: status.isOverBudget ? Colors.red : Colors.grey[600]),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit_outlined, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  void _showEditBudgetDialog(Category category, double currentBudget, MonthYearKey key) {
    final controller = TextEditingController(
      text: currentBudget > 0 ? currentBudget.toInt().toString() : '',
    );
    final l10n = ref.read(localizationProvider);

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text('${l10n.translateCategoryName(category.id, category.name)} (${key.month}/${key.year})'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              autofocus: true,
              decoration: InputDecoration(
                labelText: l10n.locale == 'vi' ? 'Hạn mức ngân sách' : 'Budget Limit',
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
                await ref.read(monthlyBudgetFamily(key).notifier).deleteCategoryBudget(category.id);
              },
              child: Text(l10n.locale == 'vi' ? 'Xóa' : 'Clear'),
            ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              final val = double.tryParse(controller.text.replaceAll(',', ''));
              if (val != null) {
                Navigator.pop(dialogCtx);
                await ref.read(monthlyBudgetFamily(key).notifier).setCategoryBudget(category.id, val);
              }
            },
            child: Text(l10n.save),
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
