# UI Contracts: Wallet UI & UX Refinements

**Feature**: `010-wallet-ui-refinements`
**Date**: 2026-09-03

## 1. `DashboardNetWorthCard` Signature

```dart
class DashboardNetWorthCard extends StatelessWidget {
  final double netWorth;
  final String currency;
  final bool isHidden;
  final VoidCallback onTogglePrivacy;
  final dynamic l10n;

  const DashboardNetWorthCard({
    super.key,
    required this.netWorth,
    required this.currency,
    required this.isHidden,
    required this.onTogglePrivacy,
    required this.l10n,
  });
}
```

## 2. `WalletCard` Signature & Layout Contract

```dart
class WalletCard extends ConsumerWidget {
  final Wallet wallet;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onSetDefault;
  final VoidCallback? onTransfer;

  const WalletCard({
    super.key,
    required this.wallet,
    this.currency = 'VND',
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.onSetDefault,
    this.onTransfer,
  });
}
```
