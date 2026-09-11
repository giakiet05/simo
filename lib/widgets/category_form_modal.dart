import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/category.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../providers/monthly_budget_provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';
import '../utils/app_constants.dart';
import '../utils/currency_input_formatter.dart';
import '../utils/icon_data.dart';
import '../widgets/color_picker_dialog.dart';

/// Modern Modal Bottom Sheet for creating and editing categories.
class CategoryFormModal extends ConsumerStatefulWidget {
  final Category? categoryToEdit;
  final String initialType;
  final double? initialBudget;
  final MonthYearKey? monthYearKey;

  const CategoryFormModal({
    super.key,
    this.categoryToEdit,
    this.initialType = 'expense',
    this.initialBudget,
    this.monthYearKey,
  });

  /// Helper to display the modal bottom sheet smoothly.
  static Future<void> show(
    BuildContext context, {
    Category? categoryToEdit,
    String initialType = 'expense',
    double? initialBudget,
    MonthYearKey? monthYearKey,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CategoryFormModal(
        categoryToEdit: categoryToEdit,
        initialType: initialType,
        initialBudget: initialBudget,
        monthYearKey: monthYearKey,
      ),
    );
  }

  @override
  ConsumerState<CategoryFormModal> createState() => _CategoryFormModalState();
}

class _CategoryFormModalState extends ConsumerState<CategoryFormModal> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _budgetController;
  late TextEditingController _searchIconController;

  late String _selectedType;
  String? _selectedIcon;
  String? _selectedColor;
  String _iconSearchQuery = '';
  bool _isSubmitting = false;

  static const List<String> _quickColors = [
    '#EF4444', // Red
    '#F97316', // Orange
    '#F59E0B', // Amber
    '#10B981', // Emerald
    '#14B8A6', // Teal
    '#06B6D4', // Cyan
    '#3B82F6', // Blue
    '#6366F1', // Indigo
    '#8B5CF6', // Purple
    '#EC4899', // Pink
    '#64748B', // Slate
  ];

  @override
  void initState() {
    super.initState();
    final cat = widget.categoryToEdit;
    _selectedType = cat?.type ?? widget.initialType;
    _selectedIcon = cat?.icon ?? (_selectedType == 'income' ? 'attach_money' : 'shopping_bag');
    _selectedColor = cat?.color ?? (_selectedType == 'income' ? '#10B981' : '#EF4444');

    _nameController = TextEditingController(text: cat?.name ?? '');

    double? budget = widget.initialBudget ?? cat?.budgetLimit;
    _budgetController = TextEditingController(
      text: budget != null && budget > 0 ? NumberFormat('#,###').format(budget.toInt()) : '',
    );
    _searchIconController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    _searchIconController.dispose();
    super.dispose();
  }

  Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      return _selectedType == 'income' ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    }
    try {
      final hex = colorStr.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (_) {
      return _selectedType == 'income' ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    }
  }

  List<String> _getFilteredIcons() {
    final allKeys = CategoryIconData.iconMap.keys.toList();
    if (_iconSearchQuery.trim().isEmpty) {
      return allKeys;
    }
    final q = _iconSearchQuery.trim().toLowerCase();
    return allKeys.where((k) => k.toLowerCase().contains(q)).toList();
  }

  Future<void> _submit() async {
    final isSystem = widget.categoryToEdit?.id.startsWith('sys_') ?? false;
    final name = _nameController.text.trim();
    if (name.isEmpty && !isSystem) return;

    setState(() => _isSubmitting = true);
    final l10n = ref.read(localizationProvider);

    try {
      final budgetStr = _budgetController.text.replaceAll(',', '').trim();
      final double? budget = budgetStr.isNotEmpty ? double.tryParse(budgetStr) : null;

      if (budget != null && budget > AppConstants.maxAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppConstants.maxAmountError(l10n))),
        );
        setState(() => _isSubmitting = false);
        return;
      }

      if (widget.categoryToEdit != null) {
        // Edit existing
        final cat = widget.categoryToEdit!;
        await ref.read(categoryProvider.notifier).updateCategory(
              cat.id,
              isSystem ? cat.name : name,
              _selectedType,
              icon: _selectedIcon,
              color: _selectedColor,
              budgetLimit: budget,
            );

        // If context has a monthYearKey, sync monthly budget too
        if (widget.monthYearKey != null) {
          if (budget != null && budget > 0) {
            await ref
                .read(monthlyBudgetFamily(widget.monthYearKey!).notifier)
                .setCategoryBudget(cat.id, budget);
          } else {
            await ref
                .read(monthlyBudgetFamily(widget.monthYearKey!).notifier)
                .deleteCategoryBudget(cat.id);
          }
        }
      } else {
        // Create new
        await ref.read(categoryProvider.notifier).createCategory(
              name,
              _selectedType,
              icon: _selectedIcon,
              color: _selectedColor,
              budgetLimit: budget,
            );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.categoryToEdit != null
                  ? (l10n.locale == 'vi' ? 'Đã cập nhật danh mục!' : 'Category updated!')
                  : l10n.categoryAdded,
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.error}: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.categoryToEdit != null;
    final isSystem = widget.categoryToEdit?.id.startsWith('sys_') ?? false;
    final settings = ref.watch(settingsProvider);
    final currencySymbol = CurrencyService.getSymbol(settings.value?.currency ?? 'VND');

    final previewColor = _parseColor(_selectedColor);
    final iconData = CategoryIconData.getIcon(_selectedIcon) ??
        (_selectedType == 'income' ? Icons.attach_money : Icons.shopping_bag);
    final iconColor = ThemeData.estimateBrightnessForColor(previewColor) == Brightness.light
        ? Colors.black87
        : Colors.white;

    final filteredIcons = _getFilteredIcons();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Drag Handle & Title
            Padding(
              padding: const EdgeInsets.only(top: 12, left: 20, right: 12),
              child: Column(
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? l10n.editCategory : l10n.addCategory,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Divider(height: 1),

            // Scrollable Form Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HERO LIVE PREVIEW
                      Center(
                        child: Column(
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              curve: Curves.easeOutCubic,
                              width: 68,
                              height: 68,
                              decoration: BoxDecoration(
                                color: previewColor,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: previewColor.withValues(alpha: 0.4),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: Icon(iconData, color: iconColor, size: 34),
                            ),
                            const SizedBox(height: 12),
                            if (isSystem)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.grey.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  l10n.locale == 'vi' ? 'Danh mục hệ thống' : 'System Category',
                                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // TYPE SEGMENTED TOGGLE (Thu / Chi)
                      if (!isSystem) ...[
                        Container(
                          height: 44,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey[850] : Colors.grey[200],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedType = 'expense';
                                      _selectedColor = '#EF4444';
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: _selectedType == 'expense' ? const Color(0xFFEF4444) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: _selectedType == 'expense'
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_upward_rounded,
                                          size: 16,
                                          color: _selectedType == 'expense' ? Colors.white : theme.textTheme.bodyMedium?.color,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          l10n.expense,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: _selectedType == 'expense' ? Colors.white : theme.textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _selectedType = 'income';
                                      _selectedColor = '#10B981';
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    decoration: BoxDecoration(
                                      color: _selectedType == 'income' ? const Color(0xFF10B981) : Colors.transparent,
                                      borderRadius: BorderRadius.circular(9),
                                      boxShadow: _selectedType == 'income'
                                          ? [
                                              BoxShadow(
                                                color: const Color(0xFF10B981).withValues(alpha: 0.3),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              ),
                                            ]
                                          : null,
                                    ),
                                    alignment: Alignment.center,
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.arrow_downward_rounded,
                                          size: 16,
                                          color: _selectedType == 'income' ? Colors.white : theme.textTheme.bodyMedium?.color,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          l10n.income,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 13,
                                            color: _selectedType == 'income' ? Colors.white : theme.textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // CATEGORY NAME
                      Text(
                        l10n.categoryName,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _nameController,
                        enabled: !isSystem,
                        decoration: InputDecoration(
                          hintText: l10n.locale == 'vi' ? 'Nhập tên danh mục...' : 'Enter category name...',
                          prefixIcon: const Icon(Icons.label_outline_rounded),
                          filled: isSystem,
                          fillColor: isSystem ? (isDark ? Colors.grey[850] : Colors.grey[200]) : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        validator: (val) {
                          if (!isSystem && (val == null || val.trim().isEmpty)) {
                            return l10n.locale == 'vi' ? 'Vui lòng nhập tên danh mục' : 'Please enter category name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // MONTHLY BUDGET (Integrated seamlessly for expense)
                      if (_selectedType == 'expense') ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.locale == 'vi' ? 'Hạn mức chi tiêu tháng' : 'Monthly Spending Limit',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              l10n.locale == 'vi' ? '(Tùy chọn)' : '(Optional)',
                              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _budgetController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [CurrencyInputFormatter()],
                          decoration: InputDecoration(
                            hintText: '0 $currencySymbol',
                            prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                            suffixText: currencySymbol,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],

                      // INLINE COLOR PALETTE
                      Text(
                        l10n.locale == 'vi' ? 'Chọn màu sắc' : 'Choose Color',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _quickColors.length + 1,
                          separatorBuilder: (context, index) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            if (index == _quickColors.length) {
                              // Custom color button
                              return InkWell(
                                onTap: () async {
                                  final result = await showDialog<String>(
                                    context: context,
                                    builder: (context) => ColorPickerDialog(
                                      selectedColor: _selectedColor,
                                    ),
                                  );
                                  if (result != null) {
                                    setState(() => _selectedColor = result);
                                  }
                                },
                                borderRadius: BorderRadius.circular(21),
                                child: Container(
                                  width: 42,
                                  height: 42,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.grey.withValues(alpha: 0.4), width: 1.5),
                                  ),
                                  child: const Icon(Icons.colorize_rounded, size: 18),
                                ),
                              );
                            }

                            final colorHex = _quickColors[index];
                            final color = _parseColor(colorHex);
                            final isSelected = _selectedColor?.toUpperCase() == colorHex.toUpperCase();

                            return GestureDetector(
                              onTap: () => setState(() => _selectedColor = colorHex),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSelected ? theme.colorScheme.primary : Colors.white.withValues(alpha: 0.8),
                                    width: isSelected ? 3 : 1.5,
                                  ),
                                  boxShadow: isSelected
                                      ? [
                                          BoxShadow(
                                            color: color.withValues(alpha: 0.5),
                                            blurRadius: 8,
                                            offset: const Offset(0, 2),
                                          ),
                                        ]
                                      : null,
                                ),
                                child: isSelected
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                                    : null,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 20),

                      // INLINE ICON PICKER
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            l10n.locale == 'vi' ? 'Biểu tượng' : 'Icon',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${filteredIcons.length} icons',
                            style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Icon search bar
                      TextField(
                        controller: _searchIconController,
                        onChanged: (v) => setState(() => _iconSearchQuery = v),
                        decoration: InputDecoration(
                          hintText: l10n.locale == 'vi' ? 'Tìm biểu tượng (ví dụ: food, car, card...)' : 'Search icon...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _iconSearchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18),
                                  onPressed: () {
                                    _searchIconController.clear();
                                    setState(() => _iconSearchQuery = '');
                                  },
                                )
                              : null,
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Grid of icons
                      Container(
                        height: 180,
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[900] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                        ),
                        child: filteredIcons.isEmpty
                            ? Center(
                                child: Text(
                                  l10n.locale == 'vi' ? 'Không tìm thấy icon nào' : 'No icons found',
                                  style: TextStyle(color: Colors.grey[500], fontSize: 13),
                                ),
                              )
                            : GridView.builder(
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 6,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: filteredIcons.length,
                                itemBuilder: (context, index) {
                                  final iconKey = filteredIcons[index];
                                  final currentIcon = CategoryIconData.getIcon(iconKey) ?? Icons.category;
                                  final isSelected = _selectedIcon == iconKey;

                                  return InkWell(
                                    onTap: () => setState(() => _selectedIcon = iconKey),
                                    borderRadius: BorderRadius.circular(10),
                                    child: AnimatedContainer(
                                      duration: const Duration(milliseconds: 150),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? previewColor.withValues(alpha: 0.2)
                                            : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: isSelected
                                            ? Border.all(color: previewColor, width: 2)
                                            : Border.all(color: Colors.transparent),
                                      ),
                                      child: Icon(
                                        currentIcon,
                                        size: 24,
                                        color: isSelected ? previewColor : theme.textTheme.bodyMedium?.color,
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 24),

                      // SAVE BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: FilledButton(
                          onPressed: _isSubmitting ? null : _submit,
                          style: FilledButton.styleFrom(
                            backgroundColor: previewColor,
                            foregroundColor: iconColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                                )
                              : Text(
                                  isEdit ? l10n.save : l10n.add,
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
