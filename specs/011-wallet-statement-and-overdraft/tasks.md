# Tasks: Wallet Statement Filtering & Overdraft Management (Sao kê nâng cao & Quản lý ví thấu chi/âm)

**Branch**: `011-wallet-statement-and-overdraft` | **Spec**: [specs/011-wallet-statement-and-overdraft/spec.md](spec.md) | **Plan**: [specs/011-wallet-statement-and-overdraft/plan.md](plan.md)

## Phase 1: Setup

**Purpose**: Localization and dictionary setup

- [x] T001 [P] Add localization strings for overdraft warning and statement filters in `lib/utils/localization.dart`

---

## Phase 2: User Story 1 - Overdraft Transfers & Negative Balance Handling (Priority: P1) 🎯 MVP

**Goal**: Allow overdraft transfers with explicit user confirmation dialog instead of a hard blocking error.

**Independent Test**: Transfer more than the source wallet balance; verify warning popup appears; confirm and verify wallet balance becomes negative.

### Implementation for User Story 1
- [x] T002 [US1] Update `WalletTransferModal` in `lib/widgets/wallet_transfer_modal.dart` to show confirmation dialog on overdraft and proceed with transfer when confirmed

**Checkpoint**: Overdraft transfer with confirmation dialog is operational

---

## Phase 3: User Story 2 - Comprehensive Statement Filtering in Wallet Detail Screen (Priority: P1)

**Goal**: Provide statement filtering by transaction type (All, Income, Expense, Transfers) and time period in `WalletDetailScreen`.

**Independent Test**: Open WalletDetailScreen; tap filter chips and change month; verify filtered statement activities and recalculation of Inflow/Outflow summaries.

### Implementation for User Story 2
- [x] T003 [US2] Implement filter chips (All, Income, Expense, Transfers) and month/period selector in `lib/screens/wallet_detail_screen.dart`

**Checkpoint**: Statement filtering and monthly auditing work smoothly

---

## Phase 4: User Story 3 - Dynamic Alert Gradient in Wallet Detail Screen (Priority: P1)

**Goal**: Hero Card in `WalletDetailScreen` dynamically renders Crimson Red alert gradient when the wallet has a negative balance.

**Independent Test**: View detail of a wallet with negative balance; verify red background; view positive wallet; verify custom color background.

### Implementation for User Story 3
- [x] T004 [P] [US3] Update Hero Card in `lib/screens/wallet_detail_screen.dart` to apply Crimson Red gradient when `wallet.currentBalance < 0`

**Checkpoint**: Negative balance alerts are visually distinct in detail view

---

## Phase 5: User Story 4 - Fixed-Width Amount Box with Auto-Scaling in WalletCard (Priority: P2)

**Goal**: Enforce a fixed-width container (`115dp`) for the amount section in `WalletCard` with `FittedBox` auto-scaling.

**Independent Test**: Render `WalletCard` with 50-character name and 15-digit amount; verify clean alignment and no text clipping.

### Implementation for User Story 4
- [x] T005 [P] [US4] Enforce fixed-width auto-scaling amount box in `lib/widgets/wallet_card.dart`

**Checkpoint**: WalletCard layout is robust across all amount sizes

---

## Phase 6: Polish & Verification

**Purpose**: Build verification and quality gate

- [ ] T006 Run all unit tests with `flutter test --concurrency=1 test/unit/`
- [ ] T007 Verify debug build with `flutter build apk --debug`
