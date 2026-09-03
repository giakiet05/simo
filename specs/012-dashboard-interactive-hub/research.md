# Research & Decisions: Interactive Dashboard Financial Hub & Metric Navigation

**Feature**: `012-dashboard-interactive-hub`
**Date**: 2026-09-03

## 1. Unified 2x2 Monthly Metrics Grid Architecture

### Decision
Extract Income & Expense from inside `MonthlyCashflowCard` and combine them with Lent & Borrowed from `_buildLoanSummary` into a dedicated component: `MonthlyMetricsGrid` (or direct 2x2 layout in `dashboard_screen.dart`).
- **Card 1 (Top-Left)**: 🟢 **Thu nhập (Income)**
  - Icon: `Icons.arrow_downward_rounded` in green container
  - Label: `Thu nhập` (Income)
  - Amount: `+15,000,000 ₫`
  - Action: Tap $\rightarrow$ Navigates to `TransactionScreen` (or switches tab).
- **Card 2 (Top-Right)**: 🔴 **Chi tiêu (Expense)**
  - Icon: `Icons.arrow_upward_rounded` in red container
  - Label: `Chi tiêu` (Expense)
  - Amount: `-8,500,000 ₫`
  - Action: Tap $\rightarrow$ Navigates to `TransactionScreen`.
- **Card 3 (Bottom-Left)**: 🟠 **Cho vay (Lent)**
  - Icon: `Icons.call_made_rounded` in orange container
  - Label: `Cần thu hồi` (Lent / To Collect)
  - Amount: `3,000,000 ₫`
  - Action: Tap $\rightarrow$ Navigates to `LoanScreen`.
- **Card 4 (Bottom-Right)**: 🟣 **Đi vay (Borrowed)**
  - Icon: `Icons.call_received_rounded` in purple container
  - Label: `Nợ phải trả` (Borrowed / Debt)
  - Amount: `5,000,000 ₫`
  - Action: Tap $\rightarrow$ Navigates to `LoanScreen`.

### Rationale
- Creates visual equilibrium and groups all monthly flow & loan obligations together.
- Highly actionable: each tile has an intuitive tap target.

---

## 2. Interactive Navigation Map

| Dashboard Component | Target Screen / Action | Route Mechanism |
| :--- | :--- | :--- |
| `MonthlyCashflowCard` | `StatisticsScreen` | `Navigator.push(context, MaterialPageRoute(builder: (_) => const StatisticsScreen()))` |
| Income Metric Tile | `TransactionScreen` | `Navigator.push(context, ...)` or switch tab index |
| Expense Metric Tile | `TransactionScreen` | `Navigator.push(context, ...)` or switch tab index |
| Lent Metric Tile | `LoanScreen` | `Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanScreen(initialTab: 1)))` |
| Borrowed Metric Tile | `LoanScreen` | `Navigator.push(context, MaterialPageRoute(builder: (_) => const LoanScreen(initialTab: 0)))` |
| Budget Overview Card | `CategoryBudgetScreen` | `Navigator.push(context, MaterialPageRoute(builder: (_) => const CategoryBudgetScreen()))` |
| Saving Goals Carousel | `SavingGoalsScreen` | `Navigator.push(context, MaterialPageRoute(builder: (_) => const SavingGoalsScreen()))` |
