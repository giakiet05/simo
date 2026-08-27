# Data Model & State Specifications: Dashboard & Wallet Integration

**Feature**: `009-dashboard-wallet-integration`
**Date**: 2026-08-26

## 1. Entities & UI State Models

### 1.1 `Wallet` (Existing Model from 008)
Represents an individual financial account.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `String` (UUID) | Primary Key |
| `name` | `String` | Wallet Name (e.g. "Vietcombank", "Ví tiền mặt", "MoMo") |
| `type` | `String` | Enum: `'cash'`, `'bank'`, `'ewallet'`, `'credit'`, `'savings'`, `'other'` |
| `initialBalance` | `double` | Initial starting balance when wallet was created (not a transaction) |
| `currentBalance` | `double` | Computed dynamic balance |
| `color` | `String` | Hex color code (e.g. `"#10B981"`, `"#3B82F6"`) |
| `icon` | `String` | Icon key identifier |
| `isDefault` | `bool` | Default payment wallet |
| `excludeFromTotal` | `bool` | Flag to exclude from Top Net Worth calculation |
| `createdAt` | `DateTime` | Creation timestamp |
| `updatedAt` | `DateTime` | Last update timestamp |

---

### 1.2 `DashboardNetWorthState` (Computed UI State)
Computed aggregate state for Dashboard Tier 1.

| Field | Type | Description |
| :--- | :--- | :--- |
| `totalNetWorth` | `double` | Sum of `currentBalance` across all wallets where `excludeFromTotal == false` |
| `wallets` | `List<Wallet>` | All active wallets sorted by `isDefault DESC, createdAt ASC` |
| `isBalanceHidden` | `bool` | Privacy masking state (`true` displays `••••••`) |

---

### 1.3 `MonthlyCashflowState` (Computed UI State for Selected Month)
Computed financial flow for Dashboard Tier 2.

| Field | Type | Description |
| :--- | :--- | :--- |
| `month` | `int` | Selected month (1-12) |
| `year` | `int` | Selected year |
| `totalIncome` | `double` | Total income recorded in the selected month |
| `totalExpense` | `double` | Total expense recorded in the selected month |
| `netCashflow` | `double` | `totalIncome - totalExpense` |
| `isSurplus` | `bool` | `netCashflow >= 0` |

---

## 2. Riverpod State Providers

```dart
// Privacy masking toggle provider
final isBalanceHiddenProvider = StateProvider<bool>((ref) => false);

// Total Net Worth provider (reactive to walletProvider)
final totalNetWorthProvider = Provider<double>((ref) {
  final walletsAsync = ref.watch(walletProvider);
  return walletsAsync.maybeWhen(
    data: (wallets) => wallets
        .where((w) => !w.excludeFromTotal)
        .fold(0.0, (sum, w) => sum + w.currentBalance),
    orElse: () => 0.0,
  );
});
```
