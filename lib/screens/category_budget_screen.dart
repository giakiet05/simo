import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../providers/settings_provider.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../theme/app_colors.dart';
import '../services/currency_service.dart';
import '../utils/icon_data.dart';
import '../widgets/icon_picker_dialog.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/category_icon_widget.dart';

class CategoryBudgetScreen extends ConsumerStatefulWidget {
  const CategoryBudgetScreen({super.key});

  @override
  ConsumerState<CategoryBudgetScreen> createState() => _CategoryBudgetScreenState();
}

class _CategoryBudgetScreenState extends ConsumerState<CategoryBudgetScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _totalBudgetController = TextEditingController();
  bool _isEditingTotal = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settingsAsync = ref.read(settingsProvider);
      settingsAsync.whenData((settings) {
        if (settings.monthlyBudget > 0) {
          _totalBudgetController.text = settings.monthlyBudget.toInt().toString();
        }
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _totalBudgetController.dispose();
    super.dispose();
  }

  void _saveTotalBudget() {
    final val = double.tryParse(_totalBudgetController.text.replaceAll(',', ''));
    if (val != null) {
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

    final String currency = settingsAsync.value?.currency ?? 'VND';
    final double totalBudget = settingsAsync.value?.monthlyBudget ?? 0.0;

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
      body: categoryAsync.when(
        data: (categories) {
          final expenseCats = categories.where((c) => c.type == 'expense').toList();
          final incomeCats = categories.where((c) => c.type == 'income').toList();

          return TabBarView(
            controller: _tabController,
            children: [
              // Expense Tab
              Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildTotalBudgetSection(totalBudget, currency),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.locale == 'vi' ? 'Ngân sách từng danh mục' : 'Category Budgets',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        FilledButton.tonal(
                          onPressed: () => _showAddCategoryDialog('expense'),
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
                    child: expenseCats.isEmpty
                        ? Center(child: Text(l10n.locale == 'vi' ? 'Chưa có danh mục chi tiêu' : 'No expense categories'))
                        : ListView.builder(
                            itemCount: expenseCats.length,
                            itemBuilder: (context, index) {
                              return _buildCategoryTile(expenseCats[index], currency);
                            },
                          ),
                  ),
                  const BannerAdWidget(key: ValueKey('cat_budget_banner_1')),
                ],
              ),
              // Income Tab
              Column(
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
                        ? Center(child: Text(l10n.locale == 'vi' ? 'Chưa có danh mục thu nhập' : 'No income categories'))
                        : ListView.builder(
                            itemCount: incomeCats.length,
                            itemBuilder: (context, index) {
                              return _buildCategoryTile(incomeCats[index], currency);
                            },
                          ),
                  ),
                  const BannerAdWidget(key: ValueKey('cat_budget_banner_2')),
                ],
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildTotalBudgetSection(double totalBudget, String currency) {
    if (_isEditingTotal) {
      return Row(
        children: [
          Expanded(
            child: TextField(
              controller: _totalBudgetController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: InputDecoration(
                prefixText: CurrencyService.getSymbol(currency) + ' ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: _saveTotalBudget,
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

    return InkWell(
      onTap: () => setState(() => _isEditingTotal = true),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              totalBudget > 0
                  ? '${CurrencyService.getSymbol(currency)} ${NumberFormat('#,###').format(totalBudget)}'
                  : (ref.read(localizationProvider).locale == 'vi' ? 'Chưa đặt ngân sách tổng' : 'Total budget not set'),
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              ref.read(localizationProvider).locale == 'vi' ? 'Chạm để sửa ngân sách tháng này' : 'Tap to edit monthly budget',
              style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.primary.withOpacity(0.6)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryTile(Category category, String currency) {
    final hasBudget = category.budgetLimit != null && category.budgetLimit! > 0;
    
    final isSystem = category.id.startsWith('sys_');

    return InkWell(
      onTap: () => _showActionMenu(context, category),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CategoryIconWidget(category: category),
        title: Text(category.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: category.type == 'expense'
          ? (hasBudget 
            ? Text('Ngân sách: ${NumberFormat('#,###').format(category.budgetLimit)} ${CurrencyService.getSymbol(currency)}')
            : Text(ref.read(localizationProvider).locale == 'vi' ? 'Chưa đặt ngân sách' : 'Budget not set'))
          : null,
      ),
    );
  }

  void _showActionMenu(BuildContext context, Category category) {
    final l10n = ref.read(localizationProvider);
    final isSystem = category.id.startsWith('sys_');

    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: Text(isSystem ? (l10n.locale == 'vi' ? 'Sửa Icon/Màu (Hệ thống)' : 'Edit Icon/Color (System)') : l10n.edit),
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
          Color previewColor;
          if (selectedColor != null && selectedColor!.isNotEmpty) {
            try {
              previewColor = Color(int.parse(selectedColor!.substring(1), radix: 16) + 0xFF000000);
            } catch (e) {
              previewColor = selectedType == 'income' ? Colors.green : Colors.red;
            }
          } else {
            previewColor = selectedType == 'income' ? Colors.green : Colors.red;
          }

          final iconColor = ThemeData.estimateBrightnessForColor(previewColor) == Brightness.light
              ? Colors.black
              : Colors.white;

          final previewIcon = CategoryIconData.getIcon(selectedIcon) ??
              (selectedType == 'income' ? Icons.arrow_downward : Icons.arrow_upward);

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
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                                labelText: l10n.locale == 'vi' ? 'Ngân sách tháng (Tùy chọn)' : 'Monthly Budget (Optional)',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                                        if (result != null) setState(() => selectedIcon = result);
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
                                        if (result != null) setState(() => selectedColor = result);
                                      },
                                      icon: const Icon(Icons.palette),
                                      label: Text(l10n.locale == 'vi' ? 'Màu' : 'Color'),
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
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
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

                            try {
                              final budgetStr = budgetController.text.replaceAll(',', '');
                              final budget = double.tryParse(budgetStr);
                              
                              await ref.read(categoryProvider.notifier).createCategory(
                                name, selectedType, icon: selectedIcon, color: selectedColor, budgetLimit: budget
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.categoryAdded)));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: Text(l10n.add),
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
    final l10n = ref.read(localizationProvider);
    final displayName = l10n.translateCategoryName(category.id, category.name);
    final controller = TextEditingController(text: displayName);
    final formatter = NumberFormat('#,###');
    final budgetController = TextEditingController(
      text: category.budgetLimit != null && category.budgetLimit! > 0
          ? formatter.format(category.budgetLimit)
          : '',
    );
    String selectedType = category.type;
    String? selectedIcon = category.icon;
    String? selectedColor = category.color;
    final isSystem = category.id.startsWith('sys_');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          Color previewColor;
          if (selectedColor != null && selectedColor!.isNotEmpty) {
            try {
              previewColor = Color(int.parse(selectedColor!.substring(1), radix: 16) + 0xFF000000);
            } catch (e) {
              previewColor = selectedType == 'income' ? Colors.green : Colors.red;
            }
          } else {
            previewColor = selectedType == 'income' ? Colors.green : Colors.red;
          }

          final iconColor = ThemeData.estimateBrightnessForColor(previewColor) == Brightness.light
              ? Colors.black
              : Colors.white;

          final previewIcon = CategoryIconData.getIcon(selectedIcon) ??
              (selectedType == 'income' ? Icons.arrow_downward : Icons.arrow_upward);

          return Dialog(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
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
                          TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: isSystem ? (l10n.locale == 'vi' ? 'Tên danh mục (Hệ thống)' : 'Category Name (System)') : l10n.categoryName,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              filled: isSystem,
                              fillColor: isSystem ? Colors.grey[200] : null,
                            ),
                            autofocus: !isSystem,
                            enabled: !isSystem,
                          ),
                          const SizedBox(height: 12),
                          if (!isSystem && selectedType == 'expense') ...[
                            TextField(
                              controller: budgetController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              decoration: InputDecoration(
                                labelText: l10n.locale == 'vi' ? 'Ngân sách tháng (Tùy chọn)' : 'Monthly Budget (Optional)',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                prefixIcon: const Icon(Icons.account_balance_wallet),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ] else if (isSystem && selectedType == 'expense') ...[
                            TextField(
                              controller: budgetController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              decoration: InputDecoration(
                                labelText: l10n.locale == 'vi' ? 'Ngân sách tháng (Tùy chọn)' : 'Monthly Budget (Optional)',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
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
                                            categoryType: selectedType,
                                          ),
                                        );
                                        if (result != null) setState(() => selectedIcon = result);
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
                                        if (result != null) setState(() => selectedColor = result);
                                      },
                                      icon: const Icon(Icons.palette),
                                      label: Text(l10n.locale == 'vi' ? 'Màu' : 'Color'),
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
                    padding: const EdgeInsets.fromLTRB(24, 4, 24, 12),
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

                            try {
                              final budgetStr = budgetController.text.replaceAll(',', '');
                              final budget = double.tryParse(budgetStr);

                              await ref.read(categoryProvider.notifier).updateCategory(
                                category.id, 
                                isSystem ? category.name : name, 
                                selectedType, 
                                icon: selectedIcon, 
                                color: selectedColor, 
                                budgetLimit: budget
                              );
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.categoryUpdated)));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
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
    final displayName = l10n.translateCategoryName(category.id, category.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteCategory),
        content: Text('${l10n.deleteCategoryConfirm} "$displayName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              try {
                await ref.read(categoryProvider.notifier).deleteCategory(category.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.categoryDeleted)));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.error}: $e')));
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) return newValue;
    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) return newValue.copyWith(text: '');
    double value = double.parse(newText);
    final formatter = NumberFormat('#,###');
    String newString = formatter.format(value);
    return newValue.copyWith(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
