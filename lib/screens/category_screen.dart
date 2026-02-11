import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../models/category.dart';

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
                      childAspectRatio: 1.5,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final category = categories[index];
                      final displayName = l10n.translateCategoryName(category.id, category.name);
                    return Card(
                      child: InkWell(
                        onLongPress: () => _showActionMenu(context, ref, category),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                category.type == 'income'
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: category.type == 'income' ? Colors.green : Colors.red,
                                size: 32,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                displayName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                category.type == 'income' ? l10n.income : l10n.expense,
                                style: TextStyle(
                                  fontSize: 12,
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

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.addCategory),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: l10n.categoryName,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: l10n.type,
                  border: const OutlineInputBorder(),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                try {
                  await ref
                      .read(categoryProvider.notifier)
                      .createCategory(name, selectedType);
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
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Category category) {
    final l10n = ref.read(localizationProvider);
    final displayName = l10n.translateCategoryName(category.id, category.name);
    final controller = TextEditingController(text: displayName);
    String selectedType = category.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(l10n.editCategory),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: l10n.categoryName,
                  border: const OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: InputDecoration(
                  labelText: l10n.type,
                  border: const OutlineInputBorder(),
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
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () async {
                final name = controller.text.trim();
                if (name.isEmpty) return;

                try {
                  await ref
                      .read(categoryProvider.notifier)
                      .updateCategory(category.id, name, selectedType);
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
