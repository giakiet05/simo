# Tasks: Wallet UI & UX Refinements (Tinh chỉnh & Tối ưu Giao diện Ví tiền)

**Branch**: `010-wallet-ui-refinements` | **Spec**: [specs/010-wallet-ui-refinements/spec.md](spec.md) | **Plan**: [specs/010-wallet-ui-refinements/plan.md](plan.md)

## Phase 1: Setup

**Purpose**: Style and visual constants alignment

- [x] T001 [P] Prepare dynamic color palette helpers in `lib/widgets/dashboard/dashboard_net_worth_card.dart`

---

## Phase 2: User Story 1 - Dynamic Hero Card Background & Clean Dashboard Header (Priority: P1) 🎯 MVP

**Goal**: Dashboard Net Worth Hero card shifts colors dynamically based on solvency ($\ge 0$ is Emerald Green, $< 0$ is Crimson Red) and removes redundant inline buttons.

**Independent Test**: View Dashboard with positive/negative balances and verify green/red gradients; verify no redundant buttons inside the card.

### Implementation for User Story 1
- [x] T002 [P] [US1] Update `DashboardNetWorthCard` in `lib/widgets/dashboard/dashboard_net_worth_card.dart` with dynamic gradient colors and streamlined layout without inline action buttons
- [x] T003 [US1] Update `DashboardScreen` in `lib/screens/dashboard_screen.dart` to pass simplified props to `DashboardNetWorthCard`

**Checkpoint**: User Story 1 is fully functional and clean on the Dashboard

---

## Phase 3: User Story 2 - Clean Wallets Screen Hero Card without Duplicate Action Buttons (Priority: P1)

**Goal**: Clean up the top overview card on WalletsScreen by applying dynamic gradient and removing duplicate inline buttons, maintaining primary actions in the top-right AppBar.

**Independent Test**: Open Wallets Screen; verify Hero card has no inline buttons and top-right AppBar provides Add Wallet and Transfer actions.

### Implementation for User Story 2
- [x] T004 [P] [US2] Update `WalletsScreen` in `lib/screens/wallets_screen.dart` to apply dynamic green/red gradient and remove duplicate inline buttons from the overview card

**Checkpoint**: User Story 2 is fully functional on WalletsScreen

---

## Phase 4: User Story 3 - Robust Wallet Card Layout for Long Currency Amounts & Long Names (Priority: P1)

**Goal**: Ensure `WalletCard` allows long wallet names to be 100% visible and formatted with multi-line wrap, gracefully accommodating large balances without layout clipping.

**Independent Test**: Test with a 40+ character wallet name and 100+ billion VND balance; verify no truncation or overflow.

### Implementation for User Story 3
- [x] T005 [P] [US3] Refactor `WalletCard` in `lib/widgets/wallet_card.dart` to use flexible multiline layout for wallet names (`maxLines: 2`, `softWrap: true`) and responsive balance presentation

**Checkpoint**: All 3 user stories are complete and responsive

---

## Phase 5: Polish & Cross-Cutting Concerns

**Purpose**: Build verification and quality gate

- [x] T006 Run all unit tests with `flutter test --concurrency=1 test/unit/`
- [x] T007 Verify debug build with `flutter build apk --debug`

---

## Dependencies & Execution Order

### Phase Dependencies
- **Phase 1 (Setup)**: Can start immediately
- **Phase 2 (US1)**: Can run immediately
- **Phase 3 (US2)**: Can run in parallel with US1
- **Phase 4 (US3)**: Can run in parallel with US1 & US2
- **Phase 5 (Polish)**: Depends on all implementation phases

### Parallel Opportunities
- `T002`, `T004`, `T005` can be implemented concurrently as they modify separate widget/screen files.
