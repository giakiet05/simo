# Research: Multi-Month Budget Management & Rich Mock Data

**Feature**: [Multi-Month Budget Management & Rich Mock Data](spec.md)  
**Date**: 2026-08-21  

---

## 1. Multi-Month Storage Strategy: SQLite vs Key-Value SharedPreferences

### Context
Previously, `monthlyBudget` was stored as a single scalar in `UserSettings` (SharedPreferences / SharedPreferences JSON), and category `budgetLimit` was stored as a column on `categories` table in SQLite. Neither approach supported time-dimensioned history (past vs present vs future months).

### Options Evaluated
1. **Option A: Extend SQLite with Dedicated Monthly Budget Tables**
   - Create `monthly_budgets` (`id`, `year`, `month`, `amount`, `created_at`, `updated_at`).
   - Create `category_monthly_budgets` (`id`, `category_id`, `year`, `month`, `amount`, `created_at`, `updated_at`).
2. **Option B: JSON Blob in SharedPreferences / Settings Table**
   - Store a map `{ "2026-03": { "total": 25000000, "categories": { "cat1": 3000000 } } }`.
3. **Option C: Add year/month columns to categories table**
   - Duplicate categories per month.

### Decision
**Option A: Extend SQLite with Dedicated Monthly Budget Tables**.

### Rationale
- Relational integrity with foreign keys to `categories.id` (`ON DELETE CASCADE`).
- Efficient indexing on `(year, month)` and `(category_id, year, month)` for instant lookup (<5ms).
- Clean separation between category taxonomy (name, icon, color) and time-bound financial constraints (monthly allocations).
- Consistent with existing SQLite architecture for transactions, recurring configs, and loans.

---

## 2. Defaulting & Inheritance Strategy Across Months

### Context
When a user sets a budget for Month $M$, what should happen when they navigate to Month $M+1$ if they haven't explicitly configured a new budget for $M+1$?

### Options Evaluated
1. **Option A: Explicit Overrides with Fallback to Latest Configured Month**
   - If Month $M+1$ has no explicit record in `monthly_budgets`, fall back to the most recent prior month's budget or global default.
2. **Option B: Independent Explicit Per-Month Records with "Copy from Previous Month" Action**
   - Each month only has a budget if explicitly set or generated. When entering an unconfigured month, UI shows 0 / "Chưa thiết lập" with a one-tap button "Sao chép ngân sách tháng trước" (Copy previous month's budget).
3. **Option C: Auto-copy upon first viewing**
   - Automatically insert records on navigation.

### Decision
**Option B: Independent Explicit Records with Graceful Fallback & Quick "Copy Previous Month" Option**.

### Rationale
- Gives users full transparency: past months are immutable unless edited, and future months don't get polluted with unintentional database writes unless confirmed by the user.
- Mock data generator can explicitly populate all 6 historical months with distinct, realistic limits.

---

## 3. Month Navigation UX Pattern Alignment

### Context
The app currently has month navigation in `StatisticsScreen` (`_selectedCategoryMonth`, `_selectedCategoryYear`) and month headers in `TransactionScreen`. The `CategoryBudgetScreen` lacked month selection, causing user confusion.

### Decision
Introduce a standardized `MonthSelectorHeader` or unified month navigation widget across:
- `CategoryBudgetScreen` (Header with `< Tháng M/YYYY >` and tap-to-pick modal).
- `StatisticsScreen` (Synchronized with category budget breakdown).
- `DashboardScreen` (Monthly budget widget displays active/selected month).

### Rationale
- Consistent user experience: navigating months works identically across all tabs in Simo.

---

## 4. Mock Data Generation Distribution Profile

### Context
User requirement specifies that mock data must feature multi-month budgets across 6 months (March 2026 to August 2026) with diverse realistic states.

### Distribution Profile:
- **Total Monthly Budget**: 25,000,000 - 32,000,000 VND per month.
- **Category Budgets**:
  - `Ăn uống` (Food & Dining): Budget ~6,000,000 - 8,000,000 VND (Usage: 75% - 105% across months).
  - `Đi lại` (Transportation): Budget ~1,500,000 - 2,500,000 VND (Usage: 60% - 90%).
  - `Mua sắm` (Shopping): Budget ~3,000,000 - 5,000,000 VND (Usage: 80% - 125% - triggers warning in high shopping months).
  - `Hóa đơn & Tiện ích` (Bills & Utilities): Budget ~2,000,000 - 3,500,000 VND (Usage: 85% - 95%).
  - `Giải trí & Du lịch` (Entertainment): Budget ~2,000,000 - 4,000,000 VND (Usage: 50% - 110%).
