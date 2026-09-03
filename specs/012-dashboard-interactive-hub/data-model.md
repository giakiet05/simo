# Presentation Models: Interactive Dashboard Financial Hub

**Feature**: `012-dashboard-interactive-hub`
**Date**: 2026-09-03

## 1. Metric Tile Model

```dart
class MetricTileData {
  final String title;
  final double amount;
  final String currency;
  final IconData icon;
  final Color color;
  final bool isMasked;
  final VoidCallback onTap;
  final String? prefix;

  const MetricTileData({
    required this.title,
    required this.amount,
    required this.currency,
    required this.icon,
    required this.color,
    required this.isMasked,
    required this.onTap,
    this.prefix,
  });
}
```
