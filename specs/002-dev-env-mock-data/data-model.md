# Data Model: Build Configuration & Mock Dataset

## 1. Build & Identity Model

| Property | Development (`debug`) | Production (`release`) | Description |
|---|---|---|---|
| `applicationId` | `com.simolab.simo.dev` | `com.simolab.simo` | Android Package ID / Sandbox boundary |
| `appName` | `Simo Dev` | `Simo` | Display name on Android launcher |
| Database Path | `/data/data/com.simolab.simo.dev/databases/simo.db` | `/data/data/com.simolab.simo/databases/simo.db` | Completely separate file storage |
| Preferences | `/data/data/com.simolab.simo.dev/shared_prefs/` | `/data/data/com.simolab.simo/shared_prefs/` | Independent SharedPreferences |

---

## 2. Mock Dataset Specification

### A. Categories (5 Income + 5 Expense)
- **Income Categories (5)**:
  1. `Lương` (Salary) - Icon: `work`, Color: `#4CAF50`
  2. `Thưởng` (Bonus) - Icon: `card_giftcard`, Color: `#8BC34A`
  3. `Đầu tư` (Investment) - Icon: `trending_up`, Color: `#009688`
  4. `Kinh doanh` (Business / Sales) - Icon: `store`, Color: `#FF9800`
  5. `Thu nhập khác` (Other Income) - Icon: `attach_money`, Color: `#00BCD4`
- **Expense Categories (5)**:
  1. `Ăn uống` (Food & Dining) - Icon: `restaurant`, Color: `#FF5722`
  2. `Đi lại` (Transportation) - Icon: `directions_car`, Color: `#F44336`
  3. `Mua sắm` (Shopping) - Icon: `shopping_bag`, Color: `#E91E63`
  4. `Hóa đơn & Tiện ích` (Bills & Utilities) - Icon: `receipt`, Color: `#673AB7`
  5. `Giải trí & Du lịch` (Entertainment & Travel) - Icon: `movie`, Color: `#9C27B0`

### B. Transactions (March 2026 – August 2026, 100+ Transactions)
- **Monthly Distribution (~18-25 transactions / month)**:
  - 2-4 income transactions per month across income categories (Salary ~15M-25M VND, Bonus, Freelance/Business).
  - 15-22 expense transactions per month across all 5 expense categories (small daily 20k-80k, medium 100k-500k, larger bills 1M-5M).
  - Total count: >= 100 transactions across 6 months.
- **Timestamps Variation**:
  - ~70% standard: `transactionDate` == `createdAt` == `updatedAt`.
  - ~15% backdated: `transactionDate` in March, `createdAt` in July.
  - ~15% edited: `updatedAt` in August, `createdAt` and `transactionDate` in March-May.

### C. Loans & Debts
- **Contacts**:
  - "Nguyễn Văn A" (Bạn thân)
  - "Trần Thị B" (Đồng nghiệp)
- **Loan Transactions**:
  - 1 Cho vay (Lending): 2,000,000 VND (with partial repayment of 1,000,000 VND).
  - 1 Đi vay (Borrowing): 5,000,000 VND (with partial repayment of 2,000,000 VND).
