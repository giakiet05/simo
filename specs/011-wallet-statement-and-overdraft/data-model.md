# Data & Filter Models: Wallet Statement Filtering & Overdraft Management

**Feature**: `011-wallet-statement-and-overdraft`
**Date**: 2026-09-03

## 1. Statement Filter State Model

```dart
enum WalletStatementTypeFilter {
  all,
  income,
  expense,
  transfer,
}

class WalletStatementFilterState {
  final WalletStatementTypeFilter typeFilter;
  final DateTime? selectedMonth; // null = All Time, or specific DateTime(year, month)

  const WalletStatementFilterState({
    this.typeFilter = WalletStatementTypeFilter.all,
    this.selectedMonth,
  });
}
```

## 2. Activity Timeline Item Model

```dart
enum WalletActivityType {
  income,
  expense,
  transferIn,
  transferOut,
}

class WalletActivityItem {
  final String id;
  final WalletActivityType type;
  final double amount;
  final double fee;
  final DateTime date;
  final String title;
  final String? subtitle;
  final String? categoryIcon;
  final String? categoryColor;
  final dynamic rawObject; // Transaction or WalletTransfer
}
```
