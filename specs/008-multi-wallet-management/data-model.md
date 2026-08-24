# Data Model: Multi-Wallet & Transfer Entities

**Feature**: `008-multi-wallet-management`

## Entities & Relationships

```
┌─────────────────────────┐
│         Wallet          │
├─────────────────────────┤
│ id (PK)                 │
│ name                    │
│ type                    │
│ initial_balance         │
│ current_balance         │
│ color                   │
│ icon                    │
│ currency                │
│ is_default              │
│ exclude_from_total      │
│ created_at / updated_at │
└───────────┬─────────────┘
            │
            ├──────────────────────────┐
            │ 1:N                      │ 1:N
            ▼                          ▼
┌─────────────────────────┐  ┌─────────────────────────┐
│       Transaction       │  │     WalletTransfer      │
├─────────────────────────┤  ├─────────────────────────┤
│ id (PK)                 │  │ id (PK)                 │
│ wallet_id (FK)          │  │ source_wallet_id (FK)   │
│ amount, type, date...   │  │ destination_wallet_idFK │
│ category_id...          │  │ amount, fee, date...    │
└─────────────────────────┘  └─────────────────────────┘
```

## 1. `Wallet` Model Specification

```dart
class Wallet {
  final String id;
  final String name;
  final String type; // 'cash', 'bank', 'ewallet', 'credit', 'savings', 'other'
  final double initialBalance;
  final double currentBalance;
  final String color;
  final String icon;
  final String? currency;
  final bool isDefault;
  final bool excludeFromTotal;
  final DateTime createdAt;
  final DateTime updatedAt;
  ...
}
```

## 2. `WalletTransfer` Model Specification

```dart
class WalletTransfer {
  final String id;
  final String sourceWalletId;
  final String destinationWalletId;
  final double amount;
  final double fee;
  final DateTime transferDate;
  final String? note;
  final DateTime createdAt;
  ...
}
```

## 3. Database Migration Definition (v14)

```sql
CREATE TABLE IF NOT EXISTS wallets (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  type TEXT NOT NULL,
  initial_balance REAL NOT NULL DEFAULT 0.0,
  current_balance REAL NOT NULL DEFAULT 0.0,
  color TEXT NOT NULL,
  icon TEXT NOT NULL,
  currency TEXT,
  is_default INTEGER NOT NULL DEFAULT 0,
  exclude_from_total INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS wallet_transfers (
  id TEXT PRIMARY KEY,
  source_wallet_id TEXT NOT NULL,
  destination_wallet_id TEXT NOT NULL,
  amount REAL NOT NULL,
  fee REAL NOT NULL DEFAULT 0.0,
  transfer_date TEXT NOT NULL,
  note TEXT,
  created_at TEXT NOT NULL,
  FOREIGN KEY (source_wallet_id) REFERENCES wallets (id) ON DELETE CASCADE,
  FOREIGN KEY (destination_wallet_id) REFERENCES wallets (id) ON DELETE CASCADE
);

ALTER TABLE transactions ADD COLUMN wallet_id TEXT;
```
