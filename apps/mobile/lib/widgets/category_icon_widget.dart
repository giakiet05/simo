import 'package:flutter/material.dart';
import '../models/category.dart';
import '../utils/icon_data.dart';

class CategoryIconWidget extends StatelessWidget {
  final Category? category;
  final String? iconName;
  final String? colorHex;
  final double size;
  final EdgeInsets? padding;
  final IconData? iconDataOverride;
  final Color? colorOverride;

  const CategoryIconWidget({
    super.key,
    this.category,
    this.iconName,
    this.colorHex,
    this.size = 40,
    this.padding,
    this.iconDataOverride,
    this.colorOverride,
  });

  @override
  Widget build(BuildContext context) {
    String? finalIconName = category?.icon ?? iconName;
    String? finalColorHex = category?.color ?? colorHex;

    final iconData = iconDataOverride ?? (finalIconName != null ? (CategoryIconData.getIcon(finalIconName) ?? Icons.category) : Icons.category);
    
    Color color = colorOverride ?? Colors.grey;
    if (colorOverride == null) {
      if (finalColorHex != null && finalColorHex.isNotEmpty) {
        try {
          String hex = finalColorHex.replaceAll('#', '');
          if (hex.length == 6) hex = 'FF$hex';
          color = Color(int.parse(hex, radix: 16));
        } catch (e) {
          // Fallback
        }
      } else if (category != null) {
        color = category!.type == 'income' ? Colors.green : Colors.red;
      }
    }

    return Container(
      width: size,
      height: size,
      margin: padding,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(iconData, color: color, size: size * 0.55),
    );
  }
}
