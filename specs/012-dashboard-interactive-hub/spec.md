# Feature Specification: Interactive Dashboard Financial Hub & Metric Navigation (Trung tâm điều phối tài chính Dashboard)

**Feature Branch**: `012-dashboard-interactive-hub`

**Created**: 2026-09-03

**Status**: Draft

**Input**: User description: "chỗ màn hình chính, dòng tiền tháng á, mày đang cho thu nhập và chi tiêu chung widget với cái dòng tiền tháng, nhưng cái nợ và cho vay lại nằm ngoài khá lạc quẻ, theo tao mày nên một là đưa thu nhập chi tiêu ra ngoài cùng style với nợ và cho vay, hai là đưa nơm và cho vày vào widget. và theo tao thì bm vào dòng tiền tháng, thu nhập chi tiêu nợ vay nó nên đưa qua màn hình nào đó, ví dụ dòng tiền tháng thì đưa vào thống kê, thu nập chi tiêu thì đưa vào tab giao dịch, nợ vay thì đưa qua tab tương ứng. mày thấy ý tưởng này có ok ko? mấy cái như giới hạn tháng, ngân sách danh mục các kiểu cũng nn điều hướng khi bm vào,"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Unified 2x2 Monthly Metrics Grid on Dashboard (Priority: P1)

Users see a balanced and visually cohesive financial overview on the Dashboard. Underneath the Monthly Net Cashflow Hero Card, 4 key monthly financial indicators are presented in a unified 2x2 grid with matching card styles and distinct color accents:
1. 🟢 **Income (Thu nhập)**: Total monthly earnings.
2. 🔴 **Expense (Chi tiêu)**: Total monthly expenditures.
3. 🟠 **Lent (Cho vay)**: Total active receivables to collect.
4. 🟣 **Borrowed (Đi vay)**: Total active liabilities/debts to repay.

**Why this priority**: Solves visual fragmentation where Loan summaries felt detached from Income/Expense summaries, creating a unified financial pulse.

**Independent Test**: Open Dashboard; verify the 2x2 grid renders Income, Expense, Lent, and Borrowed with clean symmetrical card heights, bold numbers, and standard `,` thousands separators.

**Acceptance Scenarios**:

1. **Given** user is on Dashboard, **When** reviewing the monthly pulse, **Then** all 4 indicators (Income, Expense, Lent, Borrowed) appear in a synchronized 2x2 grid below the Net Cashflow card.
2. **Given** privacy masking is enabled (`••••••••`), **When** looking at the grid, **Then** all 4 values are masked consistently.

---

### User Story 2 - Comprehensive 1-Tap Dashboard Navigation (Priority: P1)

Every financial card on the Dashboard acts as an interactive portal that routes directly to its corresponding detailed screen when tapped:
- **Monthly Net Cashflow Card** $\rightarrow$ Opens **Statistics & Analytics Screen (`StatisticsScreen`)**.
- **Income Card** $\rightarrow$ Navigates to **Transactions Tab** filtered for Income.
- **Expense Card** $\rightarrow$ Navigates to **Transactions Tab** filtered for Expense.
- **Lent / Borrowed Cards** $\rightarrow$ Opens **Loan Management Screen (`LoanScreen`)**.
- **Monthly Budget & Category Budgets Card** $\rightarrow$ Opens **Category Budget Management Screen (`CategoryBudgetScreen`)**.
- **Saving Goals Card** $\rightarrow$ Opens **Saving Goals Screen (`SavingGoalsScreen`)**.

**Why this priority**: Transforms the Dashboard from a passive read-only view into an actionable financial command center.

**Independent Test**: Tap each card on Dashboard and verify immediate navigation to the correct sub-screen without routing errors.

**Acceptance Scenarios**:

1. **Given** user is on Dashboard, **When** tapping the Monthly Net Cashflow card, **Then** `StatisticsScreen` opens.
2. **Given** user is on Dashboard, **When** tapping the Income metric card, **Then** the app switches to `TransactionScreen` scoped/filtered to Income.
3. **Given** user is on Dashboard, **When** tapping the Expense metric card, **Then** the app switches to `TransactionScreen` scoped/filtered to Expense.
4. **Given** user is on Dashboard, **When** tapping either Lent or Borrowed card, **Then** `LoanScreen` opens.
5. **Given** user is on Dashboard, **When** tapping the Budget overview card, **Then** `CategoryBudgetScreen` opens.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Dashboard MUST display a 2x2 grid containing Income, Expense, Lent, and Borrowed cards with responsive scaling.
- **FR-002**: Monthly Net Cashflow Card MUST support an `onTap` callback that navigates to `StatisticsScreen`.
- **FR-003**: Income & Expense metric cards MUST support `onTap` callbacks that navigate to `TransactionScreen`.
- **FR-004**: Lent & Borrowed metric cards MUST support `onTap` callbacks that navigate to `LoanScreen`.
- **FR-005**: Budget overview card MUST support `onTap` callback that navigates to `CategoryBudgetScreen`.
- **FR-006**: All amounts displayed across dashboard cards MUST use comma `,` thousands separators and auto-scaling constraints.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of dashboard financial cards respond to tap gestures with smooth navigation transitions.
- **SC-002**: Symmetrical 2x2 grid layout with zero overflow errors across screen widths (360dp - 480dp).
