# Presentation Models: Features Hub Screen (Màn hình Chức năng)

**Feature**: `013-features-hub-tab`
**Date**: 2026-09-03

## 1. Feature Live Preview Summaries

The `FeaturesScreen` aggregates data from existing state models into clean UI representation units:

```dart
class FeatureSection {
  final String title;
  final List<FeatureCardItem> items;

  const FeatureSection({required this.title, required this.items});
}

class FeatureCardItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;
  final Widget? trailingBadge;
  final List<FeatureCardAction>? actions;

  const FeatureCardItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
    this.trailingBadge,
    this.actions,
  });
}

class FeatureCardAction {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const FeatureCardAction({
    required this.label,
    required this.icon,
    required this.onPressed,
  });
}
```
