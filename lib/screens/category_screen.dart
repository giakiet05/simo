import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../models/category.dart';
import '../utils/icon_data.dart';
import '../widgets/icon_picker_dialog.dart';
import '../widgets/color_picker_dialog.dart';

class CategoryScreen extends ConsumerStatefulWidget {
  const CategoryScreen({super.key});

  @override
  ConsumerState<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends ConsumerState<CategoryScreen> {
  String? _selectedTypeFilter; // null = all, 'income', 'expense'

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final l10n = ref.watch(localizationProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.categories),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextButton.icon(
                onPressed: () => _showAddDialog(context, ref),
                icon: const Icon(Icons.add, color: Colors.black),
                label: Text(l10n.add, style: const TextStyle(color: Colors.black)),
              ),
            ),
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.blue[50],
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16, color: Colors.blue),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        l10n.longPressHint,
                        style: TextStyle(fontSize: 12, color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
              // Filter Chips
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    FilterChip(
                      label: Text(l10n.all),
                      selected: _selectedTypeFilter == null,
                      onSelected: (selected) {
                        setState(() {
                          _selectedTypeFilter = null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.income),
                      selected: _selectedTypeFilter == 'income',
                      selectedColor: Colors.green.withOpacity(0.3),
                      onSelected: (selected) {
                        setState(() {
                          _selectedTypeFilter = selected ? 'income' : null;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: Text(l10n.expense),
                      selected: _selectedTypeFilter == 'expense',
                      selectedColor: Colors.red.withOpacity(0.3),
                      onSelected: (selected) {
                        setState(() {
                          _selectedTypeFilter = selected ? 'expense' : null;
                        });
                      },
                    ),
                  ],
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
                        onLongPress: () => _showActionMenu(context, ref, category),
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
            ],
          );
        },
      ),
    );
  }

  void _showActionMenu(BuildContext context, WidgetRef ref, Category category) {
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
                _showEditDialog(context, ref, category);
              },
            ),
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
                              await ref
                                  .read(categoryProvider.notifier)
                                  .createCategory(name, selectedType, icon: selectedIcon, color: selectedColor);
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
    String selectedType = category.type;
    String? selectedIcon = category.icon;
    String? selectedColor = category.color;

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
                              await ref
                                  .read(categoryProvider.notifier)
                                  .updateCategory(category.id, name, selectedType, icon: selectedIcon, color: selectedColor);
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
