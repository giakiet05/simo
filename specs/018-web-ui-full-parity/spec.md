# Feature Specification: Web UI Full Feature Parity with Android App

**Feature Branch**: `018-web-ui-full-parity`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User description: "xây dựng web UI hoàn chỉnh mọi tính năng như app mobile, ưu tiên nền trắng, có darkmode, nói chung web UI phải là rep 1:1 toàn bộ tính năng của app android"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Financial Overview & Responsive Navigation (Priority: P1)

As a user accessing the Web UI on a browser (desktop/laptop/tablet), I want to see a clean, modern dashboard with my total net worth, monthly cashflow summary, budget status, recent transactions, and seamless navigation between all financial management modules, with support for both a crisp White Light Mode (default) and a dedicated Dark Mode.

**Why this priority**: The Dashboard is the central command center of the web application. Without the core layout, navigation, and overview hub, users cannot access any deeper financial management modules.

**Independent Test**: Can be fully tested by logging into the Web UI, verifying the responsive layout (Sidebar / Topbar), viewing accurate total balances across wallets, toggling between Light and Dark themes, and navigating to any feature page.

**Acceptance Scenarios**:
1. **Given** a user logged into the Web app in default Light Mode, **When** they view the Dashboard, **Then** they see a crisp white background with cards displaying Total Net Worth, Monthly Income, Monthly Expense, Budget Consumption, and a Recent Transactions list.
2. **Given** a user viewing the Web app, **When** they toggle the theme switcher in the navigation bar or settings, **Then** the entire interface smoothly transitions to Dark Mode (and persists upon page refresh).
3. **Given** a user on a desktop viewport, **When** they click any navigation item (Transactions, Wallets, Budgets, Saving Goals, Loans, Recurring, Reports, Settings), **Then** the corresponding page loads instantly without breaking state.

---

### User Story 2 - Comprehensive Transaction Management & Advanced Filtering (Priority: P1)

As a user, I want to create, edit, view details, delete, filter, and bulk-manage financial transactions (Expenses, Incomes, Transfers between wallets, and Loan records) on the Web UI with full parity to the mobile app.

**Why this priority**: Transactions are the fundamental data unit of personal finance tracking. Users must be able to log and organize expenses and income from the web browser.

**Independent Test**: Can be fully tested by creating all 4 transaction types, applying multi-parameter filters (Date range, Wallet, Category, Type, Amount), searching with fuzzy matching, and performing bulk operations (bulk delete, bulk category change).

**Acceptance Scenarios**:
1. **Given** the user is on the Transactions page, **When** they click "New Transaction", **Then** a streamlined form opens allowing them to input Amount, select Category (with icon & color), select Wallet, choose Date & Time, write Notes, and save.
2. **Given** a list of transactions grouped by date, **When** the user applies filters (e.g., Specific Wallet + Category + Date range) or types a keyword into the fuzzy search box, **Then** the list updates instantly to match the criteria.
3. **Given** multiple transactions selected via checkboxes, **When** the user triggers a bulk action (e.g., Delete, Change Category, Change Date), **Then** all selected transactions are updated in a single operation and changes are queued for synchronization.

---

### User Story 3 - Multi-Wallet & Transfer Management (Priority: P1)

As a user, I want to manage multiple financial accounts (Cash, Bank Accounts, Credit Cards, E-Wallets, Savings) and record inter-wallet transfers on the Web UI.

**Why this priority**: Accurate multi-wallet management ensures real-world alignment with user finances (e.g., tracking cash vs bank accounts vs credit card limits).

**Independent Test**: Can be fully tested by creating multiple wallets, setting a default wallet, executing a transfer between two wallets with a transfer fee, and inspecting the wallet statement history and balance progression.

**Acceptance Scenarios**:
1. **Given** the Wallets page, **When** the user creates a new wallet with an initial balance, currency, icon, color, and optional credit limit, **Then** the wallet appears in the list and contributes to the Total Net Worth (unless excluded).
2. **Given** two active wallets, **When** the user performs a Transfer from Wallet A to Wallet B with an optional transfer fee, **Then** Wallet A's balance decreases, Wallet B's balance increases, and a transfer record is logged.
3. **Given** a specific wallet clicked, **When** the user opens Wallet Detail, **Then** they see the wallet's balance trend chart, statement history, and filtered transaction history.

---

### User Story 4 - Monthly Budget & Category-Level Allocation (Priority: P2)

As a user, I want to set overall monthly spending budgets and specific category limits, tracking my spending against those budgets in real time.

**Why this priority**: Budgeting enables financial discipline and prevents overspending.

**Independent Test**: Can be fully tested by creating an overall monthly budget, setting category budgets, navigating past/future months, and verifying progress bar color thresholds (<80% normal, 80-100% warning, >100% overbudget).

**Acceptance Scenarios**:
1. **Given** the Budgets page, **When** the user sets an overall monthly budget for the current month, **Then** total monthly expenses are tracked against this limit with a visual progress bar.
2. **Given** category budget limits configured, **When** transactions in those categories are recorded, **Then** the category progress bars update with appropriate alert badges when approaching or exceeding limits.
3. **Given** the month navigation controls, **When** the user selects a previous or future month, **Then** the budget data for that specific period is displayed.

---

### User Story 5 - Saving Goals & Contribution Tracking (Priority: P2)

As a user, I want to create saving goals (e.g., Emergency Fund, New Laptop, Vacation) and track deposits/withdrawals toward those targets.

**Why this priority**: Goal-oriented savings is a key pillar of personal wealth building.

**Independent Test**: Can be fully tested by creating a saving goal with a target amount and target date, depositing funds from a wallet, and observing the progress percentage and wallet balance adjustment.

**Acceptance Scenarios**:
1. **Given** the Saving Goals page, **When** the user creates a goal with Name, Target Amount, Target Date, Color, and Icon, **Then** the goal card shows target progress and recommended monthly savings.
2. **Given** an active saving goal, **When** the user records a Deposit from a specific wallet, **Then** the goal accumulated amount increases, the wallet balance decreases, and a log entry is created.
3. **Given** a goal reaching 100% target amount, **When** viewed on the UI, **Then** it shows a completed celebration status.

---

### User Story 6 - Debt & Loan Book (Sổ nợ / Vay & Cho vay) (Priority: P2)

As a user, I want to track money borrowed from or lent to contacts, including recording partial or full repayments.

**Why this priority**: Tracking debts and receivables prevents forgotten personal loans and keeps cashflow accurate.

**Independent Test**: Can be fully tested by creating a contact, adding a "Lend" (Cho vay) or "Borrow" (Vay) record, and adding repayment transactions until fully settled.

**Acceptance Scenarios**:
1. **Given** the Loans page, **When** the user creates a Loan Contact and records a Lend transaction, **Then** the contact's receivable balance increases and total outstanding receivable is updated.
2. **Given** an active loan, **When** a repayment transaction is recorded, **Then** the remaining balance decreases and the transaction timeline logs the repayment.
3. **Given** all balances for a contact reach zero, **When** viewing the contact, **Then** the status marks as "Settled".

---

### User Story 7 - Recurring Transactions Engine (Priority: P3)

As a user, I want to configure recurring transactions (subscriptions, salary, rent) with daily, weekly, monthly, or yearly schedules.

**Why this priority**: Automates repetitive entries for consistent subscriptions and income.

**Independent Test**: Can be fully tested by creating recurring configs, previewing upcoming scheduled transactions, and verifying auto-generation logic.

**Acceptance Scenarios**:
1. **Given** the Recurring page, **When** the user creates a recurring rule with Frequency, Amount, Category, Wallet, and Start Date, **Then** it appears in the recurring schedules list.
2. **Given** scheduled recurring rules, **When** viewing the dashboard or recurring screen, **Then** upcoming due dates within the next 30 days are clearly highlighted.

---

### User Story 8 - Financial Reports, Visual Analytics & Data Export (Priority: P3)

As a user, I want to analyze spending habits with interactive charts (pie/donut category breakdown, income vs expense trends) and export data to CSV, Excel, PDF, or full JSON backup.

**Why this priority**: Visual insights and data portability give users full ownership and deep understanding of their financial habits.

**Independent Test**: Can be fully tested by viewing dynamic category breakdown charts for selected timeframes, downloading CSV/Excel/PDF reports, and creating/restoring full JSON backup archives.

**Acceptance Scenarios**:
1. **Given** the Statistics & Reports page, **When** selecting a date range, **Then** interactive charts render category spending shares, cashflow bar comparisons, and top expenditure rankings.
2. **Given** the Export & Backup screen, **When** the user clicks "Export to CSV/Excel/PDF", **Then** a filtered file download is generated immediately.
3. **Given** a JSON backup file, **When** the user uploads it via the Restore tool, **Then** an inspection summary is displayed and confirming restoration imports the data.

---

### User Story 9 - Cross-Device Real-Time Sync & Authentication (Priority: P1)

As a user, I want the web interface to synchronize data bidirectionally with the backend server and mobile devices, with offline resilience and sync status transparency.

**Why this priority**: Users expect seamless multi-device continuity between mobile and web.

**Independent Test**: Can be fully tested by signing in with Google / Email, making a change on web, and observing instant sync to the server and mobile client.

**Acceptance Scenarios**:
1. **Given** the user performs any mutation on Web (create/edit/delete), **Then** changes are debounced and synced to the backend server with `synced = 0` status handling.
2. **Given** a network disconnection, **When** the user continues interacting, **Then** mutations are stored locally in the browser storage and automatically synced upon reconnection.
3. **Given** the Sync Status indicator in the topbar, **When** sync is in progress or completed, **Then** the user sees clear visual feedback (Syncing spinner, Synced checkmark, or Error badge).

---

### Edge Cases

- **Offline Mode & Browser Storage Quotas**: How does the web UI behave if network drops or IndexedDB storage approaches browser limits? System must store mutations in IndexedDB with fallback error handling and auto-retry upon reconnection.
- **Concurrent Edits Across Devices**: If a transaction is modified on mobile and web simultaneously, the server applies Last-Write-Wins based on server timestamps.
- **Currency & Locale Formatting**: Large financial numbers (e.g. 100,000,000 VND) must be formatted cleanly with appropriate digit separators without overflow or text truncation on small screen sizes.
- **Theme Persistence**: Theme preference (Light vs Dark) must persist in local storage and match system preferences on initial visit if unset.
- **Empty State Displays**: Every module (Transactions, Wallets, Budgets, Saving Goals, Loans, Recurring) must display helpful, aesthetically pleasing empty states with direct call-to-action buttons.

---

## Requirements *(mandatory)*

### Functional Requirements

#### Design & UI Theme
- **FR-001**: System MUST provide a modern, minimalist **White Light Theme** as the default visual appearance, ensuring high contrast, clean typography, and spacious card layouts.
- **FR-002**: System MUST provide a fully styled **Dark Theme** (slate/dark palette) switchable via a single click from the navigation header and settings page.
- **FR-003**: System MUST persist the selected theme in browser storage and respect OS system color-scheme preference by default.
- **FR-004**: System MUST provide a responsive layout adapting smoothly from desktop (wide sidebar + multi-column grid) to tablet and mobile viewports (collapsible drawer / bottom bar).

#### Dashboard & Summary
- **FR-005**: System MUST display a Total Net Worth summary combining balances of all active wallets (excluding wallets marked as excluded from total).
- **FR-006**: System MUST show monthly cashflow metrics (Total Income, Total Expense, Net Balance) with comparison indicators.
- **FR-007**: System MUST provide quick-action shortcuts on the dashboard for adding transactions, initiating transfers, and managing budgets.
- **FR-008**: System MUST display visual overview widgets for Monthly Budget consumption, Saving Goals progress, and Recent Transactions.

#### Transaction Management
- **FR-009**: System MUST support creating, viewing, updating, and deleting transactions across 4 types: Expense, Income, Transfer, and Loan.
- **FR-010**: System MUST render transaction lists grouped by date with daily income/expense subtotals.
- **FR-011**: System MUST provide comprehensive filtering by Date Range (Pre-set Month, Custom Dates), Wallet, Category (multi-selection), Transaction Type, and Min/Max Amount.
- **FR-012**: System MUST provide instant and fuzzy search filtering across transaction notes and contact names.
- **FR-013**: System MUST support bulk transaction operations (multi-select to bulk delete, bulk re-categorize, bulk date change, and bulk wallet move).
- **FR-014**: System MUST provide a quick-input calculator and category selector with custom icons and colors in the transaction form.

#### Multi-Wallet Management
- **FR-015**: System MUST support multiple wallet accounts with types (Cash, Bank Account, Credit Card, E-Wallet, Savings).
- **FR-016**: System MUST support setting a primary/default wallet.
- **FR-017**: System MUST support recording inter-wallet transfers with optional transfer fees and automated double-entry ledger balance updates.
- **FR-018**: System MUST provide a Wallet Detail view showing balance history charts, statement logs, and wallet-specific transaction lists.
- **FR-019**: System MUST allow configuring credit limits and display overdraft alerts for credit card wallets.

#### Categories & Budgets
- **FR-020**: System MUST support managing hierarchical or grouped categories for both Expenses and Incomes (Name, Icon, Color, Type).
- **FR-021**: System MUST support configuring overall monthly spending budgets and individual category-level monthly budgets.
- **FR-022**: System MUST calculate real-time budget utilization with color-coded warning thresholds (Safe <80%, Warning 80-100%, Exceeded >100%).
- **FR-023**: System MUST provide multi-month navigation to view historical budget performance and set future budgets.

#### Saving Goals
- **FR-024**: System MUST support creating saving goals with Target Amount, Target Date, Custom Icon, and Color.
- **FR-025**: System MUST support recording deposits and withdrawals linked to specific wallets, adjusting wallet balances accordingly.
- **FR-026**: System MUST display goal progress percentages, remaining amounts, and target date countdowns.

#### Loans & Debts
- **FR-027**: System MUST manage loan contacts with individual outstanding receivable (lent) and payable (borrowed) balances.
- **FR-028**: System MUST support recording loan events (Lend / Borrow) and partial or full debt repayments.
- **FR-029**: System MUST provide contact settlement status badges (Active vs Settled).

#### Recurring Transactions
- **FR-030**: System MUST support scheduling recurring transactions with Daily, Weekly, Monthly, and Yearly intervals.
- **FR-031**: System MUST calculate next execution dates and show upcoming scheduled transactions preview.

#### Analytics & Export
- **FR-032**: System MUST generate interactive Category Expense/Income Breakdown charts (Donut/Pie) and Cashflow Trend charts.
- **FR-033**: System MUST export filtered transaction records to CSV, Excel (.xlsx), and PDF formats.
- **FR-034**: System MUST support full JSON Database Backup download and JSON File Restore with pre-import schema validation.

#### Synchronization & Settings
- **FR-035**: System MUST synchronize all 11 data entities bidirectionally with the backend Go server using timestamp-based incremental sync and tombstone deletion tracking.
- **FR-036**: System MUST display real-time sync status indicators in the header and provide a manual "Sync Now" button.
- **FR-037**: System MUST support user authentication (Google Sign-In / Supabase Auth / Local Session) with profile management.
- **FR-038**: System MUST support currency selection (VND, USD, EUR, JPY, GBP, etc.) with localized symbol placement and decimal formatting.
- **FR-039**: System MUST provide language switching (Vietnamese / English).
- **FR-040**: System MUST include a Mock Data Generator tool for demo and testing environments.

---

### Key Entities

- **User / Profile**: User identity, email, display name, avatar URL, preferences (theme, currency, locale).
- **Wallet**: Account holding funds (`name`, `balance`, `currency`, `type`, `icon`, `color`, `is_default`, `exclude_from_total`, `credit_limit`).
- **Wallet Transfer**: Inter-wallet money movement (`from_wallet_id`, `to_wallet_id`, `amount`, `fee`, `date`, `note`).
- **Category**: Classification for income/expense (`name`, `icon`, `color`, `type`, `parent_id`).
- **Transaction**: Financial movement record (`wallet_id`, `category_id`, `type`, `amount`, `date`, `note`, `image_url`, `synced`).
- **Monthly Budget**: Overall monthly expense cap (`month`, `year`, `amount`, `synced`).
- **Category Monthly Budget**: Specific category spending cap (`category_id`, `month`, `year`, `amount`, `synced`).
- **Saving Goal**: Savings target (`name`, `target_amount`, `current_amount`, `target_date`, `icon`, `color`, `synced`).
- **Saving Goal Log**: Deposit/withdrawal history for goals (`goal_id`, `wallet_id`, `amount`, `type`, `date`, `note`, `synced`).
- **Loan Contact**: Person involved in borrowing/lending (`name`, `phone`, `note`, `synced`).
- **Loan Transaction**: Debt creation or repayment entry (`contact_id`, `wallet_id`, `type`, `amount`, `date`, `note`, `synced`).
- **Recurring Config**: Scheduled transaction definition (`frequency`, `amount`, `category_id`, `wallet_id`, `start_date`, `end_date`, `next_run_date`, `synced`).
- **Pending Deletion**: Tombstone tracking table for deleted entities (`table_name`, `cloud_id`, `deleted_at`).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% feature parity: All 10 functional modules available in the Android mobile app (Dashboard, Transactions, Wallets, Categories, Budgets, Goals, Loans, Recurring, Reports, Settings) are fully operable in the Web UI.
- **SC-002**: First Contentful Paint (FCP) on web dashboard is under 1.2 seconds on standard broadband connections.
- **SC-003**: Theme toggle between White Light Mode and Dark Mode applies instantaneously (<50ms) across all open views without page reload.
- **SC-004**: Transaction search and filtering responds in under 100ms for datasets with up to 5,000 transactions in local browser storage.
- **SC-005**: Incremental synchronization completes in under 2 seconds when network connectivity is available.
- **SC-006**: Data exports (CSV, Excel, PDF) generate and trigger download in under 3 seconds for 1 year of financial data.
- **SC-007**: Responsive layout renders without visual clipping, horizontal scrollbars, or broken elements across screen resolutions from 768px (tablet) to 4K desktop displays.

---

## Assumptions

- The Web application uses the existing backend sync API (`/api/sync`) and authentication service endpoints.
- Browser storage (IndexedDB / LocalStorage) is available to cache user data and pending sync mutations for offline resilience.
- Default visual aesthetic is clean white minimalist background (#FFFFFF / #F8FAFC) with refined slate borders and modern card elevations, adhering to the Simo design guidelines.
- Desktop browser viewport is the primary optimization target, while maintaining responsive fluid behavior for tablet and mobile browser screens.
