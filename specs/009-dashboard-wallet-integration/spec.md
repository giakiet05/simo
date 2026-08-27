# Feature Specification: Dashboard & Wallet Integration (Tích hợp Ví tiền & Tái cấu trúc Dashboard)

**Feature Branch**: `009-dashboard-wallet-integration`

**Created**: 2026-08-26

**Status**: Draft

**Input**: User description: "tao chốt cấu trúc này nhé, phác thảo tính năng để update đi"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Total Net Worth & Mini-Wallet Carousel on Dashboard (Priority: P1)

Users open the app and instantly see their real-time financial snapshot on the Dashboard: their Total Net Worth (Tổng tài sản) across all active accounts and a horizontal carousel of their individual wallets (Tiền mặt, Ngân hàng, MoMo...) with quick action triggers for internal transfers and wallet management.

**Why this priority**: Solves the primary disconnection between the multi-wallet feature and the main dashboard. Users need to see their true available cash and account balances immediately upon opening the app without digging into nested screens.

**Independent Test**: Open Dashboard, verify Total Net Worth card shows the aggregate balance of all included wallets, tap the privacy toggle to mask/unmask numbers, scroll the mini-wallet carousel, and tap any wallet to jump into its detail statement.

**Acceptance Scenarios**:

1. **Given** user has created multiple wallets (e.g. Cash: 500k, VCB: 20M, MoMo: 5M), **When** opening Dashboard, **Then** the top Hero card displays Total Net Worth as 25.500.000 ₫ with eye icon to hide/show balances.
2. **Given** the Net Worth card is visible, **When** tapping the "Chuyển tiền" quick action button, **Then** the Wallet Transfer bottom sheet opens immediately.
3. **Given** the mini-wallet carousel below the Net Worth card, **When** user taps on a specific wallet (e.g. MoMo), **Then** the app navigates directly to that wallet's detail screen with its timeline and statement.
4. **Given** a wallet is marked "Exclude from total", **When** calculating Total Net Worth, **Then** its balance is excluded from the top Net Worth card while remaining visible with an indicator in the carousel.

---

### User Story 2 - Monthly Cash Flow Disambiguation & Dashboard Restructure (Priority: P1)

Restructure the Dashboard into two clear conceptual tiers: Top Tier (Overall Net Worth & Wallets) and Bottom Tier (Selected Month Cash Flow & Budgets). Re-label the legacy "Số dư" (Balance) card to "Dòng tiền tháng" / "Thặng dư" (Monthly Net Cash Flow) to eliminate all conceptual confusion between current total wealth and monthly savings.

**Why this priority**: Eliminates user confusion between "How much money do I have in total right now?" (Net Worth) and "How much did I save/overspend this month?" (Monthly Cash Flow).

**Independent Test**: Switch between different months in the month picker; verify that the top Net Worth card remains stable (reflecting current real wealth), while the "Dòng tiền tháng" card dynamically updates based on the selected month's Income minus Expense.

**Acceptance Scenarios**:

1. **Given** user is viewing Dashboard for Month 8/2026 with 15M income and 10M expense, **When** examining the month summary, **Then** the card displays "Thặng dư tháng: +5.000.000 ₫" (or "Dòng tiền tháng: +5.000.000 ₫") with green positive badge.
2. **Given** user has 5M income and 8M expense in Month 7/2026, **When** switching to Month 7, **Then** the card displays "Dòng tiền âm: -3.000.000 ₫" with red warning badge.
3. **Given** any selected month, **When** looking at the top of Dashboard, **Then** Total Net Worth remains the true current balance of all accounts, independent of the month filter.

---

### User Story 3 - Full Vietnamese Localization & UX Consistency (Priority: P2)

Provide 100% thorough Vietnamese localization across all wallet and transfer touchpoints, form modals, account types, and statement badges, ensuring zero untranslated English strings or ambiguous financial terminology.

**Why this priority**: Ensures seamless, natural Vietnamese user experience without jarring language switches or awkward machine translations.

**Independent Test**: Switch app language to Vietnamese and verify every label in Dashboard, Wallet Cards, Wallet Form Modals, Transfer Sheets, and Statement views is correctly translated in proper Vietnamese financial terminology.

**Acceptance Scenarios**:

1. **Given** app language is Vietnamese, **When** creating or editing a wallet, **Then** account types read "Tiền mặt", "Tài khoản ngân hàng", "Ví điện tử", "Thẻ tín dụng", "Sổ tiết kiệm", "Khác", and balance fields read "Số dư ban đầu" and "Số dư hiện tại".
2. **Given** app language is Vietnamese, **When** viewing transfer modals, **Then** labels read "Chuyển tiền nội bộ", "Ví nguồn", "Ví đích", "Phí chuyển", and "Ghi chú".

---

### Edge Cases

- **No wallets exist**: System automatically creates default "Ví tiền mặt" and displays empty state prompt to create additional bank/e-wallet accounts.
- **Privacy mode toggled**: When masked, all wallet balances on the Dashboard display as `••••••` or `*** ₫`, preserved in user session/preferences.
- **Negative wallet balance**: Credit cards or overdrawn accounts display negative balances in red badge without breaking Total Net Worth sum.
- **Large number of wallets**: Mini-wallet carousel supports horizontal scrolling without clipping, stuttering, or layout overflow on compact screens.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Dashboard MUST display a top Hero card presenting Total Net Worth (Tổng tài sản) aggregating all non-excluded wallet balances.
- **FR-002**: Dashboard Net Worth card MUST provide an eye icon toggle to obscure/reveal all sensitive balances.
- **FR-003**: Dashboard MUST include a horizontal mini-wallet carousel directly beneath the Net Worth card showing all active wallets.
- **FR-004**: Each mini-wallet card in the carousel MUST show wallet icon, squircle color background, account name, and current balance.
- **FR-005**: Tapping any mini-wallet card MUST navigate directly to the Wallet Detail & Statement screen.
- **FR-006**: Dashboard Net Worth card MUST provide quick action buttons for "Chuyển tiền" (Internal Transfer) and "Ví tiền" (All Wallets management).
- **FR-007**: The monthly overview card in Dashboard MUST be re-labeled from "Số dư" to "Dòng tiền tháng" / "Thặng dư tháng" (Monthly Cash Flow = Income - Expense for selected month).
- **FR-008**: Changing the month selector MUST ONLY affect the Monthly Cash Flow, Budgets, Category Breakdown, and Recent Transactions, while leaving the top Net Worth card reflecting real-time total wealth.
- **FR-009**: All wallet-related terminology across the app MUST be 100% localized in natural Vietnamese (Tiền mặt, Ngân hàng, Ví điện tử, Thẻ tín dụng, Tiết kiệm, Số dư ban đầu, Chuyển tiền nội bộ, Sao kê ví).

### Key Entities

- **Wallet**: Represents a distinct financial account (Cash, Bank, E-wallet, Credit Card, Savings) with attributes: `id`, `name`, `type`, `initial_balance`, `current_balance`, `color`, `icon`, `is_default`, `exclude_from_total`.
- **WalletTransfer**: Represents an internal movement of funds between two wallets with attributes: `id`, `source_wallet_id`, `destination_wallet_id`, `amount`, `fee`, `transfer_date`, `note`.
- **MonthlyCashflowSummary**: Computed summary for a specific month representing `total_income`, `total_expense`, `net_cashflow` (`income - expense`), and `savings_rate`.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can check their total wealth and individual account balances within 1 second of opening the app.
- **SC-002**: 100% of wallet-related UI text is properly localized in Vietnamese when the app is in Vietnamese mode.
- **SC-003**: 0% confusion between monthly cash surplus and total wealth, as verified by clear visual separation into Top Tier (Net Worth) and Bottom Tier (Monthly Cash Flow).
- **SC-004**: Tapping a wallet card in the Dashboard carousel opens its detailed statement view with zero perceptible delay (< 150ms transition).

## Assumptions

- SQLite database schema v14 (from feature 008) is already in place and supports wallets and transfers.
- Net Worth calculation excludes wallets flagged with `exclude_from_total = 1`.
- Privacy masking state is kept in memory or settings preferences for seamless session experience.
