# Research: Multi-Wallet & Transfer Management Architecture

**Feature**: `008-multi-wallet-management`

## 1. Database Schema Migration (Version 14)

### Schema Changes
- **New Table `wallets`**:
  - `id TEXT PRIMARY KEY`
  - `name TEXT NOT NULL`
  - `type TEXT NOT NULL` (`cash`, `bank`, `ewallet`, `credit`, `savings`, `other`)
  - `initial_balance REAL NOT NULL DEFAULT 0.0`
  - `current_balance REAL NOT NULL DEFAULT 0.0`
  - `color TEXT NOT NULL`
  - `icon TEXT NOT NULL`
  - `currency TEXT`
  - `is_default INTEGER NOT NULL DEFAULT 0`
  - `exclude_from_total INTEGER NOT NULL DEFAULT 0`
  - `created_at TEXT NOT NULL`
  - `updated_at TEXT NOT NULL`

- **New Table `wallet_transfers`**:
  - `id TEXT PRIMARY KEY`
  - `source_wallet_id TEXT NOT NULL`
  - `destination_wallet_id TEXT NOT NULL`
  - `amount REAL NOT NULL`
  - `fee REAL NOT NULL DEFAULT 0.0`
  - `transfer_date TEXT NOT NULL`
  - `note TEXT`
  - `created_at TEXT NOT NULL`
  - Foreign keys with `ON DELETE CASCADE`

- **Update Table `transactions`**:
  - `ALTER TABLE transactions ADD COLUMN wallet_id TEXT;`

### Legacy Data Migration Strategy
1. On migration to v14, if `wallets` table is empty, auto-insert a default Cash Wallet:
   - `id`: `default_cash_wallet`
   - `name`: `Ví tiền mặt` (or `Cash Wallet` based on locale)
   - `type`: `cash`
   - `initial_balance`: `0.0`
   - `color`: `#10B981` (Emerald)
   - `icon`: `wallet`
   - `is_default`: `1`
2. Backfill all existing transactions where `wallet_id IS NULL` to `default_cash_wallet`.
3. Recalculate `current_balance` of `default_cash_wallet` as `initial_balance + sum(income) - sum(expense)`.

---

## 2. Real-Time Balance & Atomic Operations

- **Transaction Creation/Update/Deletion**:
  - Executed inside a SQLite transaction:
    - Expense: `wallet.current_balance -= amount`
    - Income: `wallet.current_balance += amount`
    - Edit: Revert old amount from old wallet, apply new amount to new wallet.
    - Delete: Revert amount from wallet.
- **Internal Wallet Transfer**:
  - Executed inside a SQLite transaction:
    - `sourceWallet.current_balance -= (amount + fee)`
    - `destinationWallet.current_balance += amount`
    - If fee > 0, an expense transaction for fee can optionally be recorded or tracked in `wallet_transfers`.
  - Transfer amounts are excluded from standard income/expense statistics so financial reporting remains 100% accurate.

---

## 3. UI / UX Design Adherence

- Designed in accordance with `docs/design_system/`:
  - **`WalletsScreen`**:
    - AppBar with title and `IconButton(icon: Icon(Icons.add))` to create a new wallet.
    - Hero Overview Card with "Tổng tài sản" (Total Available Net Worth) and total balance.
    - Horizontal scrollable filter chips (`SingleChildScrollView(scrollDirection: Axis.horizontal)`).
    - Wallet cards with squircle icons (`12dp` radius, soft tint background), balance, and default badge.
    - Bottom `BannerAdWidget()`.
  - **`WalletFormModal`**:
    - Modal bottom sheet with `Radius.circular(20)`.
    - Initial balance field with `CurrencyInputFormatter` (`1,000,000`).
    - Palette picker and icon selector.
  - **`WalletTransferModal`**:
    - Source & destination wallet dropdowns.
    - Comma-formatted transfer amount and fee inputs.
    - Date picker and note field.
  - **`WalletDetailScreen`**:
    - Specific statement timeline of transactions and transfers.
    - Quick "Chuyển tiền" (Transfer) button.
