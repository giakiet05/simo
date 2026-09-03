# UI Contracts: Interactive Dashboard Financial Hub

**Feature**: `012-dashboard-interactive-hub`
**Date**: 2026-09-03

## 1. `MonthlyCashflowCard` Contract

```dart
class MonthlyCashflowCard extends StatelessWidget {
  final double netCashflow;
  final double savingsRate;
  final String currency;
  final bool isHidden;
  final dynamic l10n;
  final VoidCallback? onTap;

  const MonthlyCashflowCard({
    super.key,
    required this.netCashflow,
    required this.savingsRate,
    required this.currency,
    required this.isHidden,
    required this.l10n,
    this.onTap,
  });
}
```

## 2. `MonthlyMetricsGrid` Contract

```dart
class MonthlyMetricsGrid extends StatelessWidget {
  final double income;
  final double expense;
  final double totalLent;
  final double totalBorrowed;
  final String currency;
  final bool isHidden;
  final dynamic l10n;
  final VoidCallback? onIncomeTap;
  final VoidCallback? onExpenseTap;
  final VoidCallback? onLentTap;
  final VoidCallback? onBorrowedTap;

  const MonthlyMetricsGrid({
    super.key,
    required this.income,
    required this.expense,
    required this.totalLent,
    required this.totalBorrowed,
    required this.currency,
    required this.isHidden,
    required this.l10n,
    this.onIncomeTap,
    this.onExpenseTap,
    this.onLentTap,
    this.onBorrowedTap,
  });
}
```
