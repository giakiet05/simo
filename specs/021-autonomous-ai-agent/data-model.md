# Data Model: Autonomous AI Agent Architecture

**Feature**: [spec.md](./spec.md) | **Date**: 2026-09-17

## 1. Domain Entities & Models

### AgentTool (Interface)
Defines an executable capability registered in the Agent Tool Registry.
- `name` (String, unique identifier, e.g., `'budget_set'`, `'query_transactions'`)
- `description` (String, human and LLM readable explanation of tool intent)
- `parametersSchema` (Map<String, dynamic>, JSON Schema for arguments)
- `isDestructive` (bool, indicates if operation requires explicit confirmation)

### AiMessage (Enriched)
Core conversational unit exchanged between user and assistant.
- `id` (String, UUID)
- `role` (AiMessageRole: `user`, `assistant`, `system`)
- `content` (String, text message)
- `timestamp` (DateTime)
- `status` (AiMessageStatus: `idle`, `sending`, `thinking`, `executed`, `error`)
- `errorMessage` (String?, optional failure description)
- `actions` (List<AiExecutedAction>, mutation operations performed)
- `viewPayload` (AiViewPayload?, optional query result for Generative UI rendering)

### AiViewPayload (Abstract & Concrete Variants)
Encapsulates structured data for rich interactive Generative UI cards in chat:
- `TransactionListViewPayload`:
  - `title` (String, e.g. "Chi tiêu hôm nay")
  - `totalAmount` (double)
  - `transactionType` (String: 'expense' | 'income' | 'all')
  - `items` (List<TransactionViewItem>: id, amount, note, categoryName, categoryIcon, walletName, date)
- `WalletSummaryViewPayload`:
  - `totalNetWorth` (double)
  - `wallets` (List<WalletViewItem>: id, name, type, balance, icon)
- `BudgetProgressViewPayload`:
  - `month` (String, YYYY-MM)
  - `totalLimit` (double)
  - `totalSpent` (double)
  - `percentage` (double)
  - `categories` (List<CategoryBudgetViewItem>: categoryName, spent, limit, percentage, status)
- `DebtLedgerViewPayload`:
  - `totalReceivable` (double, people owe user)
  - `totalPayable` (double, user owes people)
  - `contacts` (List<DebtContactViewItem>: id, name, type, remainingAmount)
- `SavingGoalsViewPayload`:
  - `goals` (List<GoalViewItem>: id, name, targetAmount, currentAmount, percentage, deadline)

### AgentMemoryContext
Working context state managed by the Memory Engine.
- `messages` (List<AiMessage>, full session history for UI)
- `workingHistory` (List<Map<String, String>>, sliding window of exactly 10 recent turns)
- `memoryHorizonIndex` (int, index in messages list where active 10-turn window starts)
- `financialSnapshot` (Map<String, dynamic>, compact state of balances, categories, active loans, budgets)

---

## 2. Tool Registry Specification

### Write Tools (Mutations)
| Tool Name | Parameters | Target System |
| :--- | :--- | :--- |
| `transaction_create` | `amount`, `type`, `categoryId`, `walletId`, `note`, `date` | `TransactionNotifier` |
| `transaction_delete` | `transactionId`, `note` | `TransactionNotifier` |
| `transaction_update` | `transactionId`, `amount`, `categoryId`, `walletId`, `note` | `TransactionNotifier` |
| `wallet_create` | `name`, `type`, `initialBalance`, `currency` | `WalletNotifier` |
| `wallet_adjust_balance` | `walletId`, `newBalance`, `note` | `WalletNotifier` |
| `transfer` | `sourceWalletId`, `destinationWalletId`, `amount`, `fee`, `note` | `WalletNotifier` |
| `budget_set` | `categoryId`, `amount`, `month` | `MonthlyBudgetNotifier` |
| `loan_create` | `contactName`, `contactId`, `amount`, `loanType`, `walletId`, `note` | `LoanNotifier` |
| `loan_repay` | `contactName`, `contactId`, `amount`, `repayType`, `walletId`, `note` | `LoanNotifier` |
| `goal_create` | `name`, `targetAmount`, `targetDate` | `SavingGoalNotifier` |
| `goal_deposit` | `goalId`, `amount`, `walletId`, `note` | `SavingGoalNotifier` |
| `goal_withdraw` | `goalId`, `amount`, `walletId`, `note` | `SavingGoalNotifier` |
| `recurring_create` | `amount`, `type`, `categoryId`, `walletId`, `frequency`, `dayOfMonth`, `note` | `RecurringNotifier` |

### Read Tools (Generative UI Queries)
| Tool Name | Parameters | Output Payload |
| :--- | :--- | :--- |
| `query_transactions` | `period` ('today'\|'yesterday'\|'this_week'\|'this_month'), `categoryId`, `walletId`, `type`, `minAmount`, `maxAmount` | `TransactionListViewPayload` |
| `view_wallets` | `walletId` (optional) | `WalletSummaryViewPayload` |
| `view_budgets` | `month` (optional), `categoryId` (optional) | `BudgetProgressViewPayload` |
| `view_debts` | `type` ('lent'\|'borrowed'\|'all') | `DebtLedgerViewPayload` |
| `view_goals` | `goalId` (optional) | `SavingGoalsViewPayload` |

### Navigation Tool
| Tool Name | Parameters | Target Route |
| :--- | :--- | :--- |
| `navigate_screen` | `destination` ('dashboard'\|'reports'\|'wallets'\|'budgets'\|'loans'\|'goals'\|'export_backup'\|'settings') | App Navigator |
