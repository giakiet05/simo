# Feature Specification: Streamline Transaction Form

**Feature Branch**: `015-streamline-transaction-form`

**Created**: 2026-09-05

**Status**: Draft

**Input**: User description: "sẵn lên kế hoạch update cái phần thêm sửa giao dịch cho dễ xài luôn"

## Clarifications

### Session 2026-09-05
- Q: Có giữ nguyên bàn phím custom (CustomNumPad) với các phím tính toán (+, -, *, /) và phím số nhanh (000) không? → A: Giữ nguyên 100% bàn phím custom và logic tính toán tiện lợi đó, đảm bảo trải nghiệm nhập số tiền và phép tính quen thuộc, không thay thế bằng bàn phím hệ thống thông thường.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Fast and Intuitive Single Transaction Creation (Priority: P1)

As a daily user tracking expenses, I want to quickly input an expense or income with minimal taps so that recording my daily spending takes only a few seconds without friction.

**Why this priority**: Creating transactions is the core, most frequent action in the app (done multiple times a day). If the creation form is cluttered, uses nested dropdowns, or requires too many clicks, users will abandon habit tracking.

**Independent Test**: Can be tested by opening the Add Transaction screen, toggling between Expense and Income with one tap, entering an amount via an integrated numeric/calculator keypad, tapping a visual category icon from a grid, picking a wallet, and saving successfully.

**Acceptance Scenarios**:

1. **Given** the user opens the Add Transaction screen, **When** the screen loads, **Then** the Expense type is selected by default, the cursor is ready on the prominent amount display, and the primary categories are displayed in an accessible icon grid.
2. **Given** the user enters an amount (e.g., 45,000 or a calculation like 30000 + 15000), **When** the calculation resolves, **Then** the evaluated total is clearly shown with currency formatting.
3. **Given** the user switches between Expense and Income, **When** the tab changes, **Then** the category grid immediately updates to show categories matching that transaction type.
4. **Given** the user selects a category and wallet, **When** tapping the Save button, **Then** the transaction is recorded and the user returns to the transaction feed with instant feedback.

---

### User Story 2 - Clear and Context-Preserving Edit Mode (Priority: P2)

As a user correcting past entries, I want to edit an existing transaction with all original details pre-filled clearly so that I can modify the amount, category, wallet, note, or date without losing previous context.

**Why this priority**: Users frequently make typos, change categories, or adjust notes after paying. Editing must be accurate, transparent, and preserve original timestamps.

**Independent Test**: Can be tested by selecting an existing transaction, tapping Edit, modifying one or more fields (e.g., changing wallet from Cash to Bank, adjusting amount), and saving to verify that the record updates properly without creating duplicates.

**Acceptance Scenarios**:

1. **Given** an existing transaction is opened in Edit mode, **When** the form appears, **Then** the title displays "Edit Transaction", the original type, formatted amount, category, wallet, note, and date are pre-selected.
2. **Given** the user is in Edit mode, **When** reviewing the date, **Then** the original date and quick-date shortcuts (Today, Yesterday, Original Date) are clearly available.
3. **Given** the user changes the wallet or category and saves, **When** returning to the detail view, **Then** the updated values are reflected immediately.

---

### User Story 3 - Continuous & Multi-Item Entry Flow (Priority: P3)

As a user entering multiple receipts at once (e.g., at the end of the day or after grocery shopping), I want a "Save & Add Another" option or a clean multi-item mode so that I don't have to repeatedly reopen the creation screen from scratch.

**Why this priority**: Improves power-user workflow during bulk receipt entry while keeping the single-entry interface clean and uncluttered.

**Independent Test**: Can be tested by entering a transaction, tapping "Save & Add Another", verifying that the first transaction is saved while the form resets amount and note but keeps the selected wallet and date for fast consecutive inputs.

**Acceptance Scenarios**:

1. **Given** the user finishes filling in a transaction, **When** selecting "Save & Add Another", **Then** the transaction is committed, and the form remains open with a fresh amount field while retaining the current wallet and date context.
2. **Given** the user is done with consecutive additions, **When** tapping the standard "Save" button on the final entry, **Then** the entry is saved and the screen closes.

---

### Edge Cases

- **Zero or Negative Amounts**: What happens when the user enters 0 or negative numbers in the amount? The save action must remain disabled until a positive valid amount greater than 0 is calculated.
- **Formula Syntax Errors**: What happens when the user types an incomplete formula (e.g., "50000 +")? The interface displays the current partial expression and safely treats the evaluable prefix or disables saving until the expression is mathematically valid.
- **Extreme Amounts**: How does the system handle amounts exceeding safe transaction limits? The input display prevents overflow and warns the user if an entered number exceeds the maximum allowed transaction limit.
- **Category Deletion / Missing Category**: What happens if an edited transaction belongs to a deleted category? The form indicates the category is unassigned and allows one-tap reselection.
- **Empty Wallet State**: What happens if no custom wallets exist? The system automatically defaults to the standard default Cash wallet without blocking the user.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The system MUST provide a prominent Type Selector (Expense / Income) at the top of the form with high-contrast active states, switchable in a single tap.
- **FR-002**: The system MUST display the transaction amount in a large, readable format with live thousand separators and currency symbol.
- **FR-003**: The system MUST preserve the dedicated custom numeric keypad (CustomNumPad) featuring direct arithmetic operators (+, -, *, /), instant thousands shortcut ("000"), backspace, and live formula evaluation, maintaining the familiar tactile and calculative entry experience without reverting to a generic system keyboard.
- **FR-004**: The system MUST replace long dropdown menus with an intuitive Category Grid displaying category icons, colors, and localized names.
- **FR-005**: When switching transaction type between Expense and Income, the category selector MUST dynamically filter and present only the categories matching that type.
- **FR-006**: The system MUST display a clear Wallet Picker showing wallet name, icon, and current available balance.
- **FR-007**: The system MUST offer quick date chips ("Today", "Yesterday", "2 days ago") alongside a full calendar date picker for rapid date assignment.
- **FR-008**: In Edit mode, the system MUST provide an "Original Date" shortcut chip to restore the transaction's initial date in one tap.
- **FR-009**: The system MUST provide an optional Note input field with quick-clear and multiline support.
- **FR-010**: The system MUST validate that the amount is greater than zero and a valid category is selected (or defaulted) before enabling the primary save action.
- **FR-011**: The system MUST support a "Save & Add Another" action during creation mode to streamline consecutive receipt logging.
- **FR-012**: All input interactions MUST provide clear haptic or visual feedback upon selection.

### Key Entities

- **Transaction**: Represents an individual financial movement containing amount, mathematical formula (if calculated), type (expense/income), category reference, wallet reference, note, transaction date, and audit timestamps.
- **Category**: Classifies transactions (e.g., Food, Transportation, Salary) with associated visual styling (icon, color) and type constraints (expense/income).
- **Wallet**: Financial account where the transaction funds are drawn from or deposited into, tracking current balances and account types.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can complete a standard single-expense entry in under 6 seconds from opening the form.
- **SC-002**: Total tap count required to log an expense with category and wallet is reduced by at least 40% compared to the legacy dropdown-heavy form.
- **SC-003**: 100% of arithmetic formulas evaluated in the amount field produce accurate results with zero decimal truncation errors on integers.
- **SC-004**: In usability tests, 95% of users successfully select their desired category on the first attempt without scrolling through nested menus.

## Assumptions

- The app continues to operate in a local-first offline environment where transaction creation and updates commit immediately.
- The user's preferred currency format (comma for thousand separators) remains consistent with app-wide settings.
- Categories and Wallets are already configured or seeded with defaults, ensuring the form never opens to an unusable blank state.
- Screen layouts support standard mobile portrait aspect ratios while preventing UI overflows when software or custom keypads appear.
