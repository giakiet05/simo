import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../models/category.dart';
import '../utils/icon_data.dart';
import '../widgets/icon_picker_dialog.dart';
import '../widgets/color_picker_dialog.dart';
import '../widgets/banner_ad_widget.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  String? _selectedTypeFilter; // null = all, 'income', 'expense'

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

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categories),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.add,
            onPressed: () => _showAddDialog(context, ref),
          ),
        ],
      ),
      body: categoriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('${l10n.error}: $error')),
        data: (allCategories) {
          // Apply filter
          final categories = _selectedTypeFilter != null
              ? allCategories.where((cat) => cat.type == _selectedTypeFilter).toList()
              : allCategories;

          if (allCategories.isEmpty) {
            return Center(
              child: Text(l10n.noCategories),
            );
          }

          return Column(
            children: [
              // Filter Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildCustomChip(
                        label: l10n.all,
                        isSelected: _selectedTypeFilter == null,
                        selectedColor: Theme.of(context).primaryColor,
                        onTap: () => setState(() => _selectedTypeFilter = null),
                      ),
                      const SizedBox(width: 8),
                      _buildCustomChip(
                        label: l10n.income,
                        isSelected: _selectedTypeFilter == 'income',
                        selectedColor: Colors.green,
                        onTap: () => setState(() => _selectedTypeFilter = 'income'),
                      ),
                      const SizedBox(width: 8),
                      _buildCustomChip(
                        label: l10n.expense,
                        isSelected: _selectedTypeFilter == 'expense',
                        selectedColor: Colors.red,
                        onTap: () => setState(() => _selectedTypeFilter = 'expense'),
                      ),
                    ],
                  ),
                ),
              ),
              if (categories.isEmpty)
                Expanded(
                  child: Center(
                    child: Text(l10n.noCategories),
                  ),
                )
              else
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.3,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final displayName = l10n.translateCategoryName(category.id, category.name);

                      // Get icon and color
                      final iconData = CategoryIconData.getIcon(category.icon) ??
                          (category.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward);

                      Color backgroundColor;
                      if (category.color != null && category.color!.isNotEmpty) {
                        try {
                          backgroundColor = Color(int.parse(category.color!.substring(1), radix: 16) + 0xFF000000);
                        } catch (e) {
                          backgroundColor = category.type == 'income' ? Colors.green : Colors.red;
                        }
                      } else {
                        backgroundColor = category.type == 'income' ? Colors.green : Colors.red;
                      }

                      // Determine icon color based on background brightness
                      final iconColor = ThemeData.estimateBrightnessForColor(backgroundColor) == Brightness.light
                          ? Colors.black
                          : Colors.white;

                    return Card(
                      child: InkWell(
                        onTap: () => _showActionMenu(context, ref, category),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon with badge
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  // Icon circle
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: backgroundColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      iconData,
                                      color: iconColor,
                                      size: 24,
                                    ),
                                  ),
                                  // Badge
                                  Positioned(
                                    top: -2,
                                    right: -2,
                                    child: Container(
                                      padding: const EdgeInsets.all(3),
                                      decoration: BoxDecoration(
                                        color: category.type == 'income' ? Colors.green : Colors.red,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 2),
                                      ),
                                      child: Icon(
                                        category.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: Colors.white,
                                        size: 10,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                category.type == 'income' ? l10n.income : l10n.expense,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const BannerAdWidget(key: ValueKey('category_banner_ad')),
            ],
          );
        },
      ),
    );
  }

  void _showActionMenu(BuildContext context, WidgetRef ref, Category category) {
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
              title: Text(isSystem ? 'Sửa Icon/Màu (Hệ thống)' : l10n.edit),
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(context, ref, category);
              },
            ),
            if (!isSystem)
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: Text(l10n.delete, style: const TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context, ref, category);
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    final controller = TextEditingController();
    final budgetController = TextEditingController();
    final l10n = ref.read(localizationProvider);
    String selectedType = 'expense';
    String? selectedIcon;
    String? selectedColor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Get preview colors
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
              constraints: const BoxConstraints(
                maxWidth: 500,
                maxHeight: 600,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Text(
                      l10n.addCategory,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Content
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
                          DropdownButtonFormField<String>(
                            value: selectedType,
                            decoration: InputDecoration(
                              labelText: l10n.type,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            ),
                            items: [
                              DropdownMenuItem(value: 'income', child: Text(l10n.income)),
                              DropdownMenuItem(value: 'expense', child: Text(l10n.expense)),
                            ],
                            onChanged: (value) {
                              setState(() {
                                selectedType = value!;
                              });
                              },
                            ),
                            if (selectedType == 'expense') ...[
                              const SizedBox(height: 12),
                              TextField(
                                controller: budgetController,
                                keyboardType: TextInputType.number,
                                inputFormatters: [CurrencyInputFormatter()],
                                decoration: InputDecoration(
                                  labelText: 'Ngân sách tháng (Tùy chọn)',
                                  border: const OutlineInputBorder(),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                  prefixIcon: const Icon(Icons.account_balance_wallet),
                                ),
                              ),
                            ],
                            const SizedBox(height: 12),
                          // Icon & Color section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                // Preview
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: previewColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    previewIcon,
                                    color: iconColor,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Buttons
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
                                          setState(() {
                                            selectedIcon = result;
                                          });
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
                                          setState(() {
                                            selectedColor = result;
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.palette),
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
                  // Actions
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
                              
                              await ref
                                  .read(categoryProvider.notifier)
                                  .createCategory(name, selectedType, icon: selectedIcon, color: selectedColor, budgetLimit: budget);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.categoryAdded)),
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

  void _showEditDialog(BuildContext context, WidgetRef ref, Category category) {
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
          // Get preview colors
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
              constraints: const BoxConstraints(
                maxWidth: 500,
                maxHeight: 600,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                    child: Text(
                      l10n.editCategory,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextField(
                            controller: controller,
                            decoration: InputDecoration(
                              labelText: isSystem ? 'Tên danh mục (Hệ thống)' : l10n.categoryName,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              filled: isSystem,
                              fillColor: isSystem ? Colors.grey[200] : null,
                            ),
                            autofocus: !isSystem,
                            enabled: !isSystem,
                          ),
                          const SizedBox(height: 12),
                          if (!isSystem) ...[
                            DropdownButtonFormField<String>(
                              value: selectedType,
                              decoration: InputDecoration(
                                labelText: l10n.type,
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                              ),
                              items: [
                                DropdownMenuItem(value: 'income', child: Text(l10n.income)),
                                DropdownMenuItem(value: 'expense', child: Text(l10n.expense)),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  selectedType = value!;
                                });
                              },
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (!isSystem && selectedType == 'expense') ...[
                            TextField(
                              controller: budgetController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [CurrencyInputFormatter()],
                              decoration: InputDecoration(
                                labelText: 'Ngân sách tháng (Tùy chọn)',
                                border: const OutlineInputBorder(),
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                                prefixIcon: const Icon(Icons.account_balance_wallet),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          // Icon & Color section
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                // Preview
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: previewColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    previewIcon,
                                    color: iconColor,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                // Buttons
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
                                          setState(() {
                                            selectedIcon = result;
                                          });
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
                                          setState(() {
                                            selectedColor = result;
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.palette),
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
                  // Actions
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

                              await ref
                                  .read(categoryProvider.notifier)
                                  .updateCategory(category.id, name, selectedType, icon: selectedIcon, color: selectedColor, budgetLimit: budget);
                              if (context.mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(l10n.categoryUpdated)),
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

  void _showDeleteDialog(
      BuildContext context, WidgetRef ref, Category category) {
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
                await ref
                    .read(categoryProvider.notifier)
                    .deleteCategory(category.id);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.categoryDeleted)),
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

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    String newText = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (newText.isEmpty) {
      return newValue.copyWith(text: '');
    }

    double value = double.parse(newText);
    final formatter = NumberFormat('#,###');
    String newString = formatter.format(value);

    return newValue.copyWith(
      text: newString,
      selection: TextSelection.collapsed(offset: newString.length),
    );
  }
}
