# Research & Decisions: Features Hub Screen on Bottom Navigation Bar (Màn hình Chức năng)

**Feature**: `013-features-hub-tab`
**Date**: 2026-09-03

## 1. Architecture & Navigation Placement

### Decision
Replace `LoanScreen` as the 4th tab (index 3 in `_screens`, index 3 in `BottomNavigationBar`) in `HomeScreen` with a newly created `FeaturesScreen` (`lib/screens/features_screen.dart`).
- Tab Icon: `Icons.grid_view_rounded` (unselected: `Icons.grid_view_outlined`)
- Tab Label: `Chức năng` (English: `Features`)
- `LoanScreen` remains accessible via:
  - Direct card on `FeaturesScreen`
  - Quick access shortcut on `DashboardScreen`
  - Financial metric tiles (Lent/Borrowed) on `DashboardScreen`

### Rationale
- Elevates the app's architectural ergonomics: instead of dedicating 25% of top-level navigation to loans, it provides a centralized portal for all secondary and power-user features.
- Keeps `LoanScreen` intact and fully accessible without breaking existing routes or unit tests.

---

## 2. Differentiating Features Screen from Dashboard Quick Access

### Decision
Structure the `FeaturesScreen` as a multi-section actionable workspace rather than a grid of static icons:
1. **Section 1: Dòng tiền & Tài sản (Cashflow & Accounts)**:
   - `WalletsCard`: shows active wallets count, default wallet balance, and action buttons (`Chuyển tiền`, `+ Thêm ví`).
   - `RecurringCard`: shows recurring bills count, nearest due date, and quick add button.
2. **Section 2: Kế hoạch Tài chính (Financial Planning)**:
   - `BudgetCard`: shows current month's budget utilization percentage, remaining balance, and status indicator.
   - `SavingGoalsCard`: shows active goals count and nearest goal progress bar.
3. **Section 3: Đối soát & Thống kê (Obligations & Insights)**:
   - `LoansCard`: shows total to collect (lent) and total debt to pay (borrowed) with `+ Ghi nợ` button.
   - `StatisticsCard`: shows net cashflow trends and category distribution link.
4. **Section 4: Dữ liệu & Tiện ích Mở rộng (Data & System Utilities)**:
   - `ExportCard`: Direct link to Excel, PDF, CSV export modal/screen.
   - `BackupCard`: Direct link to Google Drive / local database backup.
   - `CategoryManagementCard`: Direct link to custom category manager.

### Rationale
- Gives users high-value operational metrics before opening any deeper screen.
- Solves redundancy by providing context and mini-actions that cannot fit into Dashboard shortcuts.

---

## 3. State Management & Privacy Consistency

### Decision
Use `ConsumerWidget` or `ConsumerStatefulWidget` in `FeaturesScreen` connecting to existing Riverpod providers:
- `walletProvider`: for wallet metrics.
- `monthlyBudgetProvider`: for monthly budget utilization.
- `loanProvider`: for borrowed/lent aggregates.
- `savingGoalProvider`: for active saving goals.
- `recurringProvider`: for upcoming bills.
- `settingsProvider`: for currency.
- `privacyProvider` (`isBalanceHidden`): for masking monetary values.

### Rationale
- Zero backend/schema changes needed.
- Leverages existing reactive caches with zero performance overhead.
