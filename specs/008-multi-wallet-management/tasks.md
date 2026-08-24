# Tasks: Multi-Wallet & Transfer Management (Quản lý Đa Ví & Chuyển Tiền)

**Branch**: `008-multi-wallet-management` | **Spec**: [specs/008-multi-wallet-management/spec.md](spec.md) | **Plan**: [specs/008-multi-wallet-management/plan.md](plan.md)

## Phase 1: Setup

**Purpose**: Localization and base configuration

- [x] T001 [P] Add localization strings for Multi-Wallet and Transfers (English, Vietnamese, Chinese) in `lib/utils/localization.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data models, SQLite schema migration v14, repository layer, and legacy transaction backfill

- [x] T002 [P] Create `Wallet` entity model in `lib/models/wallet.dart`
- [x] T003 [P] Create `WalletTransfer` entity model in `lib/models/wallet_transfer.dart`
- [x] T004 Update `Transaction` entity model with `walletId` field in `lib/models/transaction.dart`
- [x] T005 Upgrade `DatabaseHelper` schema version (v14) to create `wallets` and `wallet_transfers` tables, add `wallet_id` to `transactions`, auto-create default cash wallet, and migrate legacy transactions in `lib/repositories/database_helper.dart`
- [x] T006 Implement `WalletRepository` with CRUD and atomic balance recalculation in `lib/repositories/wallet_repository.dart`
- [x] T007 [P] Add unit tests for `WalletRepository` in `test/unit/wallet_repository_test.dart`

**Checkpoint**: Foundation ready - User stories can now be implemented

---

## Phase 3: User Story 1 - Create & Manage Multiple Wallets (Priority: P1) 🎯 MVP

**Goal**: Users can view all wallets, total net worth, create new wallets with custom starting balances, icons, colors, and set default wallet.

**Independent Test**: Create multiple wallets (Cash, Bank, Momo), set default wallet, and verify total net worth reflects initial balances.

### Implementation for User Story 1
- [x] T008 [US1] Create `WalletNotifier` and `walletProvider` in `lib/providers/wallet_provider.dart`
- [x] T009 [P] [US1] Build `WalletCard` widget with squircle icons and balance badges in `lib/widgets/wallet_card.dart`
- [x] T010 [P] [US1] Build `WalletFormModal` widget with comma currency formatting in `lib/widgets/wallet_form_modal.dart`
- [x] T011 [US1] Build `WalletsScreen` with total net worth Hero card and horizontal filter chips in `lib/screens/wallets_screen.dart`

**Checkpoint**: User Story 1 (Wallets CRUD & Overview) is fully functional

---

## Phase 4: User Story 2 - Transaction Integration with Wallet Selection (Priority: P1)

**Goal**: Users can select which wallet was used for any income/expense transaction, with automatic real-time wallet balance updates.

**Independent Test**: Record an expense under a specific wallet and verify that wallet's balance decreases while other wallets remain untouched.

### Implementation for User Story 2
- [x] T012 [US2] Update `TransactionRepository` and `TransactionNotifier` to update wallet balances atomically upon create/update/delete in `lib/repositories/transaction_repository.dart` and `lib/providers/transaction_provider.dart`
- [x] T013 [P] [US2] Add wallet selector to `AddTransactionSheet` and `TransactionFormScreen` in `lib/widgets/transaction/add_transaction_sheet.dart` and `lib/screens/transaction_form_screen.dart`

**Checkpoint**: Transactions and Wallet balances are seamlessly linked

---

## Phase 5: User Story 3 - Transfer Money Between Wallets (Priority: P1)

**Goal**: Users can move funds between wallets with optional transfer fees and notes without corrupting monthly expense reports.

**Independent Test**: Transfer money from Bank to Momo with a fee, verify both balances adjust and transfer amount is excluded from monthly expense charts.

### Implementation for User Story 3
- [x] T014 [P] [US3] Build `WalletTransferModal` widget in `lib/widgets/wallet_transfer_modal.dart`
- [x] T015 [US3] Integrate Transfer action button into `WalletsScreen` and `walletProvider`

**Checkpoint**: Internal transfers work smoothly across all wallets

---

## Phase 6: User Story 4 - Wallet Detail & Dedicated Statement History (Priority: P2)

**Goal**: Dedicated account view showing filtered transactions, total in/out flows, and quick transfer options.

**Independent Test**: Open a specific wallet detail view and verify it displays only that wallet's statement history.

### Implementation for User Story 4
- [x] T016 [US4] Build `WalletDetailScreen` with statement timeline and actions in `lib/screens/wallet_detail_screen.dart`

**Checkpoint**: Account statement detail views are complete

---

## Phase 7: User Story 5 - Data Backup & Export Integration (Priority: P3)

**Goal**: Preserve wallets and transfers in JSON snapshots and multi-sheet Excel exports.

**Independent Test**: Export JSON backup with multiple wallets, clear database, restore from backup, and verify 100% wallet recovery.

### Implementation for User Story 5
- [x] T017 [P] [US5] Update `BackupSnapshot` and `BackupService` to backup/restore `wallets` and `wallet_transfers` in `lib/models/backup_snapshot.dart` and `lib/services/backup_service.dart`
- [x] T018 [P] [US5] Update `ExportService.exportToExcel` to add "Danh sách ví" sheet and "Ví thanh toán" column in `lib/services/export_service.dart`

**Checkpoint**: All 5 user stories are fully functional

---

## Phase 8: Polish & Cross-Cutting Concerns

**Purpose**: Navigation shortcuts, ad banner, and test validation

- [x] T019 Add navigation entry points for Wallets in Quick Access Hub (`lib/widgets/dashboard/quick_access_hub.dart`) and Drawer (`lib/screens/dashboard_screen.dart`)
- [x] T020 Run all unit tests with `flutter test --concurrency=1 test/unit/` and verify `flutter analyze`
