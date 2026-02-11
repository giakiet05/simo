# User Stories - Simo

## Epic 1: Settings

### US-1.1: Update Monthly Budget
**As a** user
**I want to** set and update my monthly budget
**So that** I can track my spending limit

**Acceptance Criteria:**
- User can enter a budget amount
- Budget is saved and displayed on dashboard
- User receives notification when approaching the budget limit

### US-1.2: Change Currency
**As a** user
**I want to** switch between VND and USD
**So that** I can track expenses in my preferred currency

**Acceptance Criteria:**
- User can select currency from settings (VND or USD)
- All amounts are displayed in the selected currency
- Currency change applies to all existing and new transactions

---

## Epic 2: Category Management

### US-2.1: View Categories
**As a** user
**I want to** see all available categories
**So that** I can choose appropriate categories for my transactions

**Acceptance Criteria:**
- User can view list of all categories
- System categories and custom categories are both displayed
- Categories are sorted alphabetically or by usage frequency

### US-2.2: Create Custom Category
**As a** user
**I want to** create my own categories
**So that** I can organize transactions according to my needs

**Acceptance Criteria:**
- User can create a new category with a name
- Custom category appears in the category list
- User can select custom category when creating transactions

### US-2.3: Edit Category Name
**As a** user
**I want to** rename my custom categories
**So that** I can keep my categories organized and up-to-date

**Acceptance Criteria:**
- User can edit custom category names
- System categories cannot be edited
- Updated name reflects across all transactions using that category

### US-2.4: Delete Custom Category
**As a** user
**I want to** delete categories I no longer use
**So that** I can keep my category list clean

**Acceptance Criteria:**
- User can delete custom categories
- System categories cannot be deleted
- App prompts for confirmation before deleting
- Transactions using deleted category are handled appropriately (reassign or keep as-is)

---

## Epic 3: Transaction Management

### US-3.1: Record Single Expense
**As a** user
**I want to** quickly record an expense
**So that** I can track where my money goes

**Acceptance Criteria:**
- User can enter: amount, category, optional note, type (expense)
- Transaction is saved to local database
- Transaction appears in transaction history

### US-3.2: Record Single Income
**As a** user
**I want to** record income
**So that** I can track my earnings

**Acceptance Criteria:**
- User can enter: amount, category, optional note, type (income)
- Transaction is saved to local database
- Transaction appears in transaction history

### US-3.3: Record Multiple Transactions at Once
**As a** user
**I want to** add multiple transactions in one entry
**So that** I can quickly log multiple items from a shopping trip

**Acceptance Criteria:**
- User can add multiple line items in a single form
- Each item has: amount, category, optional note
- All items are saved as separate transactions with the same timestamp
- User can remove items before saving

### US-3.4: Use Math Operations in Amount
**As a** user
**I want to** use basic math (+, -, *, /) in amount field
**So that** I can calculate totals easily

**Acceptance Criteria:**
- User can enter expressions like "50000 + 30000"
- App calculates and displays the result (80000)
- Both formula ("50000 + 30000") and result (80000) are saved
- Result is used for statistics and display

### US-3.5: View Transaction History
**As a** user
**I want to** see all my past transactions
**So that** I can review my spending and income

**Acceptance Criteria:**
- Transactions are listed in reverse chronological order (newest first)
- Each transaction shows: amount, category, note, date
- List is paginated (20 items per page)
- User can scroll to load more

### US-3.6: Search Transactions by Keyword
**As a** user
**I want to** search transactions by keyword in notes
**So that** I can quickly find specific transactions

**Acceptance Criteria:**
- User can enter search keyword
- App filters transactions containing the keyword in notes
- Search is case-insensitive
- Results update as user types

### US-3.7: Filter Transactions by Date Range
**As a** user
**I want to** filter transactions by date range
**So that** I can view transactions for a specific period

**Acceptance Criteria:**
- User can select start date and end date
- Transactions within the date range are displayed
- User can clear filters to show all transactions

### US-3.8: Filter Transactions by Category
**As a** user
**I want to** filter transactions by category
**So that** I can see spending/income for specific categories

**Acceptance Criteria:**
- User can select one or multiple categories
- Only transactions from selected categories are shown
- User can clear filter to show all categories

### US-3.9: Filter Transactions by Type
**As a** user
**I want to** filter transactions by income or expense
**So that** I can focus on one type at a time

**Acceptance Criteria:**
- User can toggle between "All", "Income only", "Expense only"
- Filtered list updates immediately
- Filter persists until user changes it

### US-3.10: Filter Transactions by Amount Range
**As a** user
**I want to** filter transactions by minimum and maximum amount
**So that** I can find large or small transactions

**Acceptance Criteria:**
- User can set min_amount and/or max_amount
- Only transactions within the range are displayed
- User can clear amount filters

### US-3.11: Edit Transaction
**As a** user
**I want to** edit a transaction
**So that** I can correct mistakes or update information

**Acceptance Criteria:**
- User can tap on a transaction to edit
- User can modify: amount, formula, category, note, type
- Updated transaction saves with new updated_at timestamp
- Changes reflect in transaction list and statistics

### US-3.12: Delete Single Transaction
**As a** user
**I want to** delete a transaction
**So that** I can remove incorrect or duplicate entries

**Acceptance Criteria:**
- User can delete a transaction from transaction details or swipe-to-delete
- App prompts for confirmation before deleting
- Deleted transaction is removed from database
- Statistics update to reflect deletion

### US-3.13: Delete Multiple Transactions
**As a** user
**I want to** select and delete multiple transactions at once
**So that** I can quickly clean up my transaction history

**Acceptance Criteria:**
- User can enter multi-select mode
- User can select multiple transactions
- User can delete all selected transactions at once
- App prompts for confirmation before deleting
- All selected transactions are removed from database

---

## Epic 4: Recurring Transactions

### US-4.1: Create Recurring Transaction
**As a** user
**I want to** set up recurring transactions (e.g., monthly salary, rent)
**So that** I don't have to manually enter them every time

**Acceptance Criteria:**
- User can create recurring config with: name, amount, category, type, frequency (daily/weekly/monthly), interval, day_of_week/day_of_month
- Recurring config is saved to local database
- Config appears in recurring list

### US-4.2: View Recurring Transactions
**As a** user
**I want to** see all my recurring configurations
**So that** I can manage them easily

**Acceptance Criteria:**
- User can view list of all recurring configs
- Each config shows: name, amount, frequency, next run date, active status
- User can filter by active/inactive status

### US-4.3: Edit Recurring Transaction
**As a** user
**I want to** modify recurring configurations
**So that** I can update them when my income/expenses change

**Acceptance Criteria:**
- User can edit all fields of a recurring config
- Changes apply to future transactions only (past transactions remain unchanged)
- Updated next_run date is calculated based on new settings

### US-4.4: Pause/Resume Recurring Transaction
**As a** user
**I want to** temporarily disable a recurring transaction
**So that** I can pause it without deleting it

**Acceptance Criteria:**
- User can toggle is_active status
- Inactive configs do not generate transactions
- User can reactivate configs later

### US-4.5: Delete Recurring Transaction
**As a** user
**I want to** delete recurring configurations I no longer need
**So that** they stop generating transactions

**Acceptance Criteria:**
- User can delete a recurring config
- App prompts for confirmation
- Past transactions generated by this config remain in history
- No future transactions are generated

### US-4.6: Auto-generate Transactions from Recurring
**As a** user
**I want** recurring transactions to be automatically created
**So that** I don't have to remember to log them manually

**Acceptance Criteria:**
- When user opens the app, check all active recurring configs
- If next_run <= today, create a transaction automatically
- Update next_run to next occurrence
- Show notification: "2 recurring transactions were created"
- User can review and edit/delete auto-generated transactions

---

## Epic 5: Statistics & Reports

### US-5.1: View Summary Dashboard
**As a** user
**I want to** see a quick summary of my finances
**So that** I can understand my financial situation at a glance

**Acceptance Criteria:**
- Dashboard shows: Total Income, Total Expense, Balance
- Summary can be filtered by date range (default: current month)
- Numbers update in real-time when transactions change

### US-5.2: View Category Breakdown Chart
**As a** user
**I want to** see a pie chart of expenses by category
**So that** I can understand where I spend most

**Acceptance Criteria:**
- Pie chart shows expense distribution across categories
- Each slice shows category name and percentage
- User can tap on a slice to see details
- Chart can be filtered by date range

### US-5.3: View Income vs Expense Trend
**As a** user
**I want to** see a line chart of income and expense over time
**So that** I can track trends and patterns

**Acceptance Criteria:**
- Line chart shows income and expense trends over time
- X-axis: dates, Y-axis: amounts
- User can select time range (week/month/year)
- Chart updates when date range changes

### US-5.4: View Budget Progress
**As a** user
**I want to** see how much of my monthly budget I've used
**So that** I can control my spending

**Acceptance Criteria:**
- Progress bar shows: spent / budget
- Display remaining budget amount
- Show warning when exceeding 80% of budget
- Show alert when exceeding budget

---

## Epic 6: Notifications & Alerts

### US-6.1: Receive Budget Warning Notification
**As a** user
**I want to** receive a notification when I'm close to my budget limit
**So that** I can control my spending before exceeding the limit

**Acceptance Criteria:**
- When total expenses reach 80% of monthly budget, show notification
- Notification shows: "You've used 80% of your monthly budget"
- User can dismiss notification
- Notification appears once per threshold

### US-6.2: Receive Budget Exceeded Notification
**As a** user
**I want to** receive a notification when I exceed my budget
**So that** I'm aware of overspending

**Acceptance Criteria:**
- When total expenses exceed monthly budget, show notification
- Notification shows: "You've exceeded your monthly budget by [amount]"
- User can dismiss notification
- Notification is persistent until user acknowledges

---

## Future Enhancements (Out of Scope for v1)

### US-7.1: In-app Chatbot
**As a** user
**I want to** interact with a chatbot to add transactions or get insights
**So that** I can manage my finances conversationally

### US-7.2: Cloud Sync & Web App
**As a** user
**I want to** access my data from multiple devices
**So that** I can manage finances from phone and computer

### US-7.3: Shared Budgets
**As a** user
**I want to** share budgets with family members
**So that** we can manage household finances together
