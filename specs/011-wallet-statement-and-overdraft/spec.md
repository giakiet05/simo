# Feature Specification: Wallet Statement Filtering & Overdraft Management (Sao kê nâng cao & Quản lý ví thấu chi/âm)

**Feature Branch**: `011-wallet-statement-and-overdraft`

**Created**: 2026-09-03

**Status**: Draft

**Input**: User description: "ví có được âm hay ko? có đuọc chuyển tiền từ ví này sang ví khác mà ví hiện tại ko đủ tiền hay ko? trong màn hình từng ví có cần thêm chip chi tiêu và thu nhập ko? có cần thêm bộ lọc vào đây giống bên tab giao dịch ko? tương tự trong màn hình ví, nếu số dư âm thì nên cho màu đỏ. nên có cơ chế thu nhỏ hoặc xuống dòng cho số tiền lớn, số tiền nên nằm trong một box cố định, nếu quá lớn thì wrap xuống dòng hoặc thu nhỏ lại hoặc kết hợp cả 2, chứ nếu ko nó sẽ ép phần nội dung sát lại."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Overdraft Transfers & Negative Balance Handling (Priority: P1)

Users can perform transactions and internal transfers even if the source wallet balance is insufficient (e.g. credit card overdraft or recording expenses before recording deferred income). When transferring more than the available balance, the app prompts with a clear warning confirmation dialog instead of a hard block, and recalculates the wallet balance into a negative state with an alert indicator.

**Why this priority**: Essential for realistic credit card tracking and prevents friction when users need to record transactions promptly.

**Independent Test**: Attempt to transfer 2M from a wallet with 500k. Verify a confirmation dialog appears ("Số dư ví nguồn không đủ, ví sẽ bị âm. Bạn có muốn tiếp tục?"). Confirm transfer; verify source wallet updates to -1.5M with a red badge.

**Acceptance Scenarios**:

1. **Given** a source wallet with balance 500k, **When** user enters transfer amount of 1M, **Then** a warning confirmation dialog appears before executing the transfer.
2. **Given** user confirms the overdraft transfer, **When** transaction completes, **Then** source wallet balance becomes -500k (plus fee if any), and destination wallet increases by 1M.
3. **Given** user cancels the confirmation, **When** dialog dismisses, **Then** no transfer is executed and balances remain untouched.

---

### User Story 2 - Comprehensive Statement Filtering in Wallet Detail Screen (Priority: P1)

Users reviewing an individual wallet in `WalletDetailScreen` can filter statements by time (Month/Year selector or All time) and by transaction type using quick filter chips: `Tất cả` (All), `Thu nhập (+)` (Income), `Chi tiêu (-)` (Expense), and `Chuyển khoản (⇄)` (Transfers).

**Why this priority**: Empowers users to audit bank accounts and e-wallets efficiently month-by-month without sifting through unrelated historical entries.

**Independent Test**: Open WalletDetailScreen for a wallet with diverse history. Tap "Chi tiêu" chip to see only expenses; tap "Chuyển khoản" chip to see only transfers; change the month dropdown to see only transactions of that specific month.

**Acceptance Scenarios**:

1. **Given** user views WalletDetailScreen, **When** tapping the "Chi tiêu" filter chip, **Then** only expense transactions for this wallet are listed in the statement.
2. **Given** user views WalletDetailScreen, **When** selecting a specific month/year, **Then** the timeline and the Inflow/Outflow summary cards recalculate strictly for that selected time period.
3. **Given** user selects "Tất cả", **When** viewing the timeline, **Then** all chronological activities (income, expense, transfer in, transfer out) are displayed.

---

### User Story 3 - Dynamic Alert Gradient in Wallet Detail Screen (Priority: P1)

When an individual wallet has a negative balance ($< 0$), its top Hero Card in `WalletDetailScreen` dynamically renders a Crimson Red alert gradient to visually signal debt or deficit, switching back to its assigned custom color when the balance is restored to positive or zero ($\ge 0$).

**Why this priority**: Provides unified, immediate visual clarity across the app that the account requires attention or debt repayment.

**Independent Test**: Open detail view for a wallet with negative balance; verify background is Crimson Red. Add income transaction to make balance positive; verify background returns to the wallet's custom color.

**Acceptance Scenarios**:

1. **Given** a wallet with `currentBalance < 0`, **When** user opens its detail screen, **Then** the Hero summary card renders in Crimson Red gradient with white text.
2. **Given** a wallet with `currentBalance >= 0`, **When** user opens its detail screen, **Then** the Hero summary card renders with the wallet's configured color gradient.

---

### User Story 4 - Fixed-Width Amount Box with Auto-Scaling in WalletCard (Priority: P2)

In `WalletCard` (and related list items), the balance display on the right is enclosed in a dedicated, fixed-width bounding box with auto-scaling (`FittedBox(fit: BoxFit.scaleDown)`). This guarantees that large balances (e.g. `999.000.000.000 ₫`) will shrink gracefully and never shrink or crowd the left-side wallet name container.

**Why this priority**: Ensures flawless visual alignment and prevents horizontal layout jitter across all devices.

**Independent Test**: Render a wallet with a 40-character name and a 12-digit balance; verify the name occupies full flexible width and the balance fits within its fixed box without layout distortion.

**Acceptance Scenarios**:

1. **Given** any currency amount length, **When** rendered in `WalletCard`, **Then** the balance is constrained within a fixed right-side width box and automatically scaled down without overflowing.
2. **Given** long wallet names, **When** displayed, **Then** the name wraps cleanly without being compressed by the amount box.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: `WalletTransferModal` MUST prompt user with a confirmation warning dialog when transfer amount + fee exceeds source wallet balance, allowing the transfer to proceed if approved.
- **FR-002**: `WalletDetailScreen` MUST include quick filter chips for `Tất cả` (All), `Thu nhập` (Income), `Chi tiêu` (Expense), and `Chuyển tiền` (Transfers).
- **FR-003**: `WalletDetailScreen` MUST provide a Month/Year selector filter to scope statement items and inflow/outflow metrics to the selected period.
- **FR-004**: `WalletDetailScreen` Hero Card MUST dynamically render a Crimson Red alert gradient when `currentBalance < 0`, and the wallet's custom color when `currentBalance >= 0`.
- **FR-005**: `WalletCard` MUST reserve a fixed-width container for the balance column, utilizing auto-scaling so that long figures never compress the wallet name.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of overdraft transfer attempts prompt clear user confirmation with zero unexpected crashes or transaction failures.
- **SC-002**: Filter operations on `WalletDetailScreen` update the statement list in under 50ms without UI lag.
- **SC-003**: 100% of wallet cards maintain visual consistency across screen sizes (360dp - 480dp) with zero text truncation on wallet names.
