import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/category_provider.dart';
import '../providers/localization_provider.dart';
import '../utils/icon_data.dart';
import '../widgets/banner_ad_widget.dart';
import '../widgets/category_form_modal.dart';

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
            onPressed: () => CategoryFormModal.show(
              context,
              initialType: _selectedTypeFilter ?? 'expense',
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
                        onTap: () => CategoryFormModal.show(
                          context,
                          categoryToEdit: category,
                        ),
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
}
