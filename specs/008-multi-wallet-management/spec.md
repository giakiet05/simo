# Feature Specification: Multi-Wallet & Transfer Management (Quản lý Đa Ví & Chuyển Tiền)

**Feature Branch**: `008-multi-wallet-management`

**Created**: 2026-08-22

**Status**: Draft

**Input**: User description: "tao thấy vụ nhiều ví ok, thử triển khia xem"

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create & Manage Multiple Wallets / Accounts (Priority: P1) 🎯 MVP

As a user with multiple financial sources (Cash, Bank Accounts, E-wallets, Savings), I want to create and manage separate wallets with custom names, account types, starting balances, colors, and icons, so that I can see the exact breakdown of my total net worth across different financial accounts.

**Why this priority**: Fundamental foundation for categorizing and segregating cash flows across distinct sources.

**Independent Test**: Can be validated by creating multiple wallets (e.g. "Tiền mặt", "Vietcombank", "Ví Momo"), editing starting balances, setting a default wallet, and verifying that the total balance correctly sums up all included wallets.

**Acceptance Scenarios**:

1. **Given** a new or existing user, **When** opening the app for the first time after update, **Then** a default "Ví tiền mặt" (Cash Wallet) is automatically created and all existing historical transactions are linked to it without data loss.
2. **Given** the Wallets screen, **When** the user taps the `+` action button in the AppBar, **Then** a modal opens allowing them to input wallet name, wallet type (Tiền mặt, Ngân hàng, Ví điện tử, Thẻ tín dụng, Khác), initial balance (formatted with commas), icon, color, and options ("Đặt làm ví mặc định", "Không tính vào tổng tài sản").
3. **Given** the wallet list, **When** viewing the Wallets screen, **Then** a Hero Overview card displays "Tổng tài sản khả dụng" (Total Available Net Worth) and a list of wallet cards showing their respective current balances and account types.

---

### User Story 2 - Transaction Integration with Wallet Selection (Priority: P1)

As a user recording a daily income or expense, I want to choose which wallet was used for the transaction, so that each wallet's balance is automatically and accurately updated in real-time.

**Why this priority**: Essential daily core workflow of recording money movement.

**Independent Test**: Record an expense of 50,000 VND using "Ví Momo", verify that "Ví Momo" balance decreases by 50,000 VND while "Tiền mặt" and "Vietcombank" remain unchanged.

**Acceptance Scenarios**:

1. **Given** the transaction entry modal / sheet, **When** creating a transaction, **Then** the user can select a specific wallet (pre-selected with the default wallet).
2. **Given** a recorded expense transaction, **When** saved, **Then** the selected wallet's current balance is deducted by the transaction amount atomically.
3. **Given** a recorded income transaction, **When** saved, **Then** the selected wallet's current balance increases by the transaction amount atomically.
4. **Given** a transaction being deleted or edited, **When** processed, **Then** the corresponding wallet balances are adjusted automatically.

---

### User Story 3 - Transfer Money Between Wallets (Priority: P1)

As a user moving funds between accounts (e.g. withdrawing ATM cash from bank account, or topping up Momo from bank), I want to execute internal wallet transfers with optional transfer fees and notes, so that my account balances adjust properly without distorting my monthly income or expense totals.

**Why this priority**: Internal transfers are not expenses or revenues; without transfer functionality, users must record artificial expense + income which corrupts financial analytics.

**Independent Test**: Transfer 1,000,000 VND from "Vietcombank" to "Tiền mặt" with 1,100 VND fee, verify Vietcombank decreases by 1,001,100 VND, Tiền mặt increases by 1,000,000 VND, and monthly report only counts the 1,100 VND fee as expense.

**Acceptance Scenarios**:

1. **Given** the Wallets screen or Wallet Detail, **When** the user taps "Chuyển tiền" (Transfer), **Then** a modal opens allowing them to select Source Wallet, Destination Wallet, Amount (with thousand comma formatting), optional Transfer Fee, Date/Time, and Note.
2. **Given** a valid transfer submission, **When** executed, **Then** the source wallet balance decreases by `(Amount + Fee)` and destination wallet balance increases by `Amount`.
3. **Given** a wallet transfer log, **When** viewing monthly income/expense totals, **Then** the transfer amount itself is excluded from expense/income charts, while any transfer fee is categorized under expenses.

---

### User Story 4 - Wallet Detail & Dedicated Statement History (Priority: P2)

As a user auditing a specific account, I want to open a dedicated wallet detail view showing its current balance, total money in, total money out, and a chronological statement of transactions and transfers for that specific wallet, so that I can reconcile my records with my real-world bank statements.

**Why this priority**: Enables precise account reconciliation and historical transparency.

**Independent Test**: Open "Vietcombank" detail screen, verify it lists only transactions and transfers associated with Vietcombank with chronological timeline.

**Acceptance Scenarios**:

1. **Given** a wallet card, **When** tapped, **Then** the user is navigated to `WalletDetailScreen` displaying account milestone statistics (Tổng tiền vào, Tổng tiền ra, Số dư hiện tại) and filtered transaction list.
2. **Given** the `WalletDetailScreen`, **When** the user taps "Chuyển tiền" or "Sửa ví", **Then** the appropriate modal opens with prefilled details.

---

### User Story 5 - Backup Snapshot & Multi-Sheet Excel Integration (Priority: P3)

As a user backing up or exporting my financial data, I want all wallets, wallet transactions, and wallet transfers preserved in full JSON snapshots and Excel spreadsheets, so that my multi-wallet data is 100% safeguarded and exportable.

**Why this priority**: Guarantees zero data loss and multi-sheet reporting consistency.

**Independent Test**: Export JSON backup with multiple wallets and transfers, clear database, restore from backup, and verify all wallets and balances match 100%.

**Acceptance Scenarios**:

1. **Given** JSON backup snapshot generation, **When** generated, **Then** `wallets` and `wallet_transfers` tables are fully serialized and restored atomically.
2. **Given** Excel multi-sheet export, **When** generated, **Then** a dedicated "Danh sách ví" sheet is created, and the "Giao dịch" sheet includes a "Ví thanh toán" column.

---

## Key Entities *(mandatory)*

- **`Wallet`**: `id`, `name`, `type` (cash, bank, ewallet, credit, savings, other), `initialBalance`, `currentBalance`, `color`, `icon`, `isDefault`, `excludeFromTotal`, `createdAt`, `updatedAt`.
- **`WalletTransfer`**: `id`, `sourceWalletId`, `destinationWalletId`, `amount`, `fee`, `transferDate`, `note`, `createdAt`.
- **`Transaction` (Updated)**: Added `walletId` foreign key linking transaction to its payment wallet.

---

## Success Criteria *(mandatory)*

1. **100% Real-Time Accuracy**: Wallet balances always match `initialBalance + sum(income) - sum(expense) + sum(transfers_in) - sum(transfers_out) - sum(transfer_fees)`.
2. **Zero Distortion on Analytics**: Internal transfers do not artificially inflate monthly income or spending statistics.
3. **Seamless Backward Compatibility**: Existing user transactions automatically map to a default cash wallet without requiring manual user intervention.
4. **100% Design System Compliant**: All new screens and modals adhere to the flat UI tokens, AppBar actions, scrollable chips, 20dp modal radii, and comma-formatted number fields.
