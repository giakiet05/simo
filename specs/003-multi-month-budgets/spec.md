# Feature Specification: Multi-Month Budget Management & Rich Mock Data

**Feature Directory**: `specs/003-multi-month-budgets`  
**Created**: 2026-08-21  
**Status**: Draft  
**Input**: User description: "update thêm phần mock data có cả budget tháng và budget danh mục luôn nha, mà hiện tại thấy có 1 điểm chưa tốt: Chưa có xem budget theo từng tháng, chỉ set được cho tháng hiện tại, nên là trong phần thống kê / danh mục phải xem được nhiều tháng y chang cái tab danh mục luôn"

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Multi-Month Budget Navigation & Historical Tracking (Priority: P1) 🎯 MVP

As a user tracking my personal finances, I want to navigate between past, present, and future months in the budget and category screens so that I can see how my spending compared to my budget limits across different months.

**Why this priority**: Currently, budget limits only reflect a single static value or current month, preventing users from reviewing past budget compliance or planning future monthly budgets. Enabling multi-month budget tracking is essential for realistic financial management.

**Independent Test**: Open the Budget & Categories screen, switch between different months using the month navigation selector, and verify that the total monthly budget and individual category budget limits, spending totals, and progress percentages update accurately for each respective month.

**Acceptance Scenarios**:

1. **Given** a user is on the Category & Budget screen, **When** they tap the month navigation arrows (previous/next) or select a specific month/year, **Then** the screen displays the total budget, category budget limits, and actual spent amounts corresponding to the selected month.
2. **Given** a user is viewing a historical month, **When** they set or update a category budget limit or total monthly budget for that month, **Then** the change is saved specifically for that selected month and does not inadvertently alter other months.
3. **Given** a user has set a budget in a previous month, **When** navigating to a new month with no customized budget, **Then** the system offers to carry over or default to the most recent budget settings.

---

### User Story 2 - Comprehensive Budget Generation in Mock Data (Priority: P1)

As a developer or tester, I want the mock data generator to create multi-month total budgets and per-category budget limits spanning all 6 mock data months (March 2026 to August 2026) so that the app's budget tracking and charts are immediately full of rich, realistic, and insightful historical data.

**Why this priority**: Rich historical budget data allows immediate testing of progress bars, warning states, over-budget indicators, and monthly trend comparisons without manual entry.

**Independent Test**: Trigger "Generate Mock Data" from Settings, navigate through the 6 generated months in the budget views, and verify that every month has a configured total budget and realistic per-category budget limits with varied compliance levels (normal, near-limit, and over-budget).

**Acceptance Scenarios**:

1. **Given** a user generates mock data, **When** they view the budget screen for any month between March 2026 and August 2026, **Then** a realistic total monthly budget (e.g., 20,000,000 - 30,000,000 VND) is configured.
2. **Given** mock data is generated, **When** inspecting individual expense categories in each month, **Then** each category has an assigned budget limit with varied usage profiles (e.g., some months under 70%, some 90-95%, and some exceeding 100% to showcase warning indicators).

---

### User Story 3 - Synchronized Multi-Month Budget in Statistics & Dashboard (Priority: P2)

As a user analyzing financial health, I want the Statistics and Dashboard views to respect the multi-month budget data when changing time periods so that my financial summaries and charts accurately compare actual expenses against that period's budget.

**Why this priority**: Consistency across all tabs ensures the user gets a coherent picture of their financial standing whether looking at the Dashboard overview, Statistics breakdown, or Category budget manager.

**Independent Test**: Change the selected month in Statistics or Dashboard, and verify that the budget progress indicators, remaining amounts, and over-budget alerts synchronize with the budget configured for that chosen month.

**Acceptance Scenarios**:

1. **Given** a user changes the month in Statistics, **When** viewing the category expense breakdown, **Then** the budget comparison against actual spending reflects the selected month's budget limits.
2. **Given** a user returns to the Dashboard, **When** viewing the monthly budget summary card, **Then** it clearly displays the current month's budget progress with accurate remaining balances.

---

### Edge Cases

- **No budget set for a selected month**: System gracefully shows zero or "No budget set" with an easy one-tap option to set a budget or copy from the prior month.
- **Transactions added/modified in a past month**: Real-time spending progress bars for that historical month automatically update without affecting other months.
- **Categories added or deleted**: Newly created categories can be assigned budgets for current or future months; deleted/archived categories retain their historical budget records in past months for data integrity.
- **High currency values or zero amounts**: Layout formats large monetary numbers cleanly without text overflow or truncation.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support defining and storing total monthly budgets per specific month and year (YYYY-MM).
- **FR-002**: System MUST support defining and storing individual category budget limits per specific month and year (YYYY-MM).
- **FR-003**: Users MUST be able to navigate backward and forward through months, as well as pick a specific month/year directly in the Budget and Category screens.
- **FR-004**: System MUST calculate actual spending vs. budget limit per category and in total for any selected month.
- **FR-005**: Mock data generator MUST automatically populate total monthly budgets and individual expense category budgets across all 6 generated months (March 2026 to August 2026).
- **FR-006**: Mock data generator MUST produce diverse budget consumption ratios (healthy spending under budget, near threshold at 80-95%, and exceeding budget > 100%) to test visual indicators.
- **FR-007**: Clearing all data MUST cleanly remove all historical monthly budgets and per-category budget allocations.
- **FR-008**: System MUST display visual indicators (normal, warning, exceeded) based on the percentage of budget consumed in the selected month.

---

## Success Criteria *(mandatory)*

- **SC-001**: Users can view and switch between historical monthly budgets across at least 12 previous and future months in under 1 second per switch.
- **SC-002**: Generating mock data creates complete, valid monthly and per-category budget records for 100% of the 6 mock data months (March 2026 to August 2026).
- **SC-003**: Spending calculations against monthly and category budgets accurately reflect 100% of recorded transactions for the chosen period.
- **SC-004**: Users can set or update any historical or future month's budget in 3 taps or fewer.

---

## Key Entities

- **Monthly Budget**: Represents the overall planned spending ceiling for a specific calendar month and year (Year, Month, Amount, Notes).
- **Category Monthly Budget**: Represents the planned spending ceiling for a specific expense category in a specific calendar month and year (Category, Year, Month, Amount).
- **Category**: The classification of financial activities (Income / Expense) which can have recurring or month-specific spending targets.
- **Transaction**: An individual financial record associated with a category, amount, and specific transaction date.
