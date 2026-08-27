# UI Contracts: Dashboard & Wallet Integration

**Feature**: `009-dashboard-wallet-integration`
**Date**: 2026-08-26

## 1. Widget Contracts

### 1.1 `DashboardNetWorthCard`
Header Hero card displaying the aggregate Net Worth and quick actions.

```dart
class DashboardNetWorthCard extends ConsumerWidget {
  final double netWorth;
  final String currency;
  final bool isHidden;
  final VoidCallback onTogglePrivacy;
  final VoidCallback onTransferTap;
  final VoidCallback onViewAllWalletsTap;

  const DashboardNetWorthCard({
    super.key,
    required this.netWorth,
    required this.currency,
    required this.isHidden,
    required this.onTogglePrivacy,
    required this.onTransferTap,
    required this.onViewAllWalletsTap,
  });
}
```

---

### 1.2 `MiniWalletCarousel`
Compact horizontal scrolling list of individual wallets.

```dart
class MiniWalletCarousel extends ConsumerWidget {
  final List<Wallet> wallets;
  final String currency;
  final bool isHidden;
  final Function(Wallet wallet) onWalletTap;
  final VoidCallback onAddWalletTap;

  const MiniWalletCarousel({
    super.key,
    required this.wallets,
    required this.currency,
    required this.isHidden,
    required this.onWalletTap,
    required this.onAddWalletTap,
  });
}
```

---

### 1.3 `MonthlyCashflowCard`
Restructured monthly summary card replacing the legacy "Balance" card.

```dart
class MonthlyCashflowCard extends StatelessWidget {
  final double income;
  final double expense;
  final double netCashflow;
  final String currency;
  final dynamic l10n;

  const MonthlyCashflowCard({
    super.key,
    required this.income,
    required this.expense,
    required this.netCashflow,
    required this.currency,
    required this.l10n,
  });
}
```
