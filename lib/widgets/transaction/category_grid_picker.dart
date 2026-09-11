import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/category.dart';
import '../../providers/localization_provider.dart';
import '../category_icon_widget.dart';

/// A responsive 4-column visual grid picker displaying category icons, colors,
/// and localized names for fast one-tap selection in the transaction form.
class CategoryGridPicker extends ConsumerWidget {
  /// The list of categories to display (typically pre-filtered by transaction type).
  final List<Category> categories;

  /// The currently selected category ID, if any.
  final String? selectedCategoryId;

  /// Callback triggered when the user taps on a category tile.
  final ValueChanged<Category> onCategorySelected;

  /// Callback triggered when the user long-presses a category tile.
  final ValueChanged<Category>? onCategoryLongPressed;

  const CategoryGridPicker({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.onCategoryLongPressed,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(localizationProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    if (categories.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        alignment: Alignment.center,
        child: Text(
          l10n.noCategoriesWarning,
          style: TextStyle(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            fontStyle: FontStyle.italic,
          ),
          textAlign: TextAlign.center,
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 14,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final isSelected = category.id == selectedCategoryId;
        final displayName = l10n.translateCategoryName(category.id, category.name);

        return InkWell(
          onTap: () => onCategorySelected(category),
          onLongPress: onCategoryLongPressed != null
              ? () => onCategoryLongPressed!(category)
              : null,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    width: isSelected ? 2.5 : 0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
                child: CategoryIconWidget(
                  category: category,
                  size: 38,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                displayName,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark ? Colors.grey[300] : Colors.grey[800]),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}
