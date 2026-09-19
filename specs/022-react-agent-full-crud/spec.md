# Feature Specification: ReAct AI Agent Architecture with Full CRUD & Multi-turn Clarification

**Feature Branch**: `022-react-agent-full-crud`

**Created**: 2026-09-19

**Status**: Draft

**Input**: User description: "Lên danh sách tính năng chuẩn bị làm cho ReAct AI Agent hỗ trợ đầy đủ các kịch bản Full CRUD (thêm, xoá, sửa trên toàn bộ 7 thực thể), tương tác hỏi lại khi mơ hồ (Clarification & Slot-Filling), quan sát kết quả thực tế (Observation Feedback), và tối ưu Prompt Caching."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Multi-turn Clarification & Ambiguity Prevention (Priority: P1)

When a user submits an ambiguous request or omits mandatory parameters (such as creating a loan without specifying who borrowed/lent the money, or requesting a wallet transfer when multiple source wallets exist), the AI Agent MUST NOT guess or use hardcoded placeholder values (e.g. "Người quen"). Instead, the Agent halts execution, asks the user a targeted clarifying question, preserves the pending action slots in memory, and seamlessly executes the action once the user answers.

**Why this priority**: Preventing incorrect data creation and financial discrepancies is the most fundamental requirement for an autonomous finance assistant.

**Independent Test**: Say "Cho bạn mượn 200k" $\to$ Verify Agent does NOT create any loan and responds "Bạn cho ai mượn 200k vậy?" $\to$ Reply "Thằng Nam" $\to$ Verify Agent creates a loan contact for "Nam" with 200.000 VND and deducts the amount from the default wallet.

**Acceptance Scenarios**:
1. **Given** a user prompt with missing mandatory fields (e.g., "Tạo khoản cho mượn 500k"), **When** processed by the agent, **Then** no database mutations occur and the agent returns a direct clarification question to the user.
2. **Given** an active clarification question in the conversation, **When** the user provides the missing information in the next turn (e.g., "Cho anh Hùng"), **Then** the agent merges the new input with the previous pending intent and executes the complete mutation accurately.
3. **Given** multiple matching entities with ambiguous names (e.g., two contacts named "Tuấn"), **When** the user requests an action on "Tuấn", **Then** the agent lists the candidates and asks the user to disambiguate.

---

### User Story 2 - Full CRUD & Update Operations Across All 7 Entities (Priority: P1)

Users can perform complete Create, Read, Update, and Delete operations on all core domain entities using natural language: Transactions, Wallets, Categories, Monthly Budgets, Loans & Debts, Saving Goals, and Recurring Configurations.

**Why this priority**: Users need the flexibility to modify existing records (renaming wallets, adjusting saving goals, extending loan due dates, changing recurring bill dates) naturally without opening manual form screens.

**Independent Test**:
- Wallets: "Đổi tên ví Momo thành MoMo Chi Tiêu và đặt làm ví mặc định" $\to$ verify wallet updated.
- Budgets: "Tăng ngân sách ăn uống tháng này từ 3 củ lên 4.5 củ" $\to$ verify monthly budget updated.
- Loans: "Sửa khoản nợ của Nam: dời ngày hẹn trả sang 30/10 và sửa lại chỉ nợ 1.5 củ" $\to$ verify loan contact & remaining balance updated.
- Goals: "Mục tiêu Mua iPhone tăng từ 20 củ lên 25 củ và dời hạn đến 31/12" $\to$ verify saving goal updated.
- Recurring: "Đổi tiền trọ định kỳ từ 3 củ lên 3.5 củ chuyển ngày chạy sang mùng 5" $\to$ verify recurring config updated.

**Acceptance Scenarios**:
1. **Given** an existing wallet, **When** the user asks to rename or change its default status, **Then** the agent executes `wallet_update` and confirms the updated status.
2. **Given** an existing saving goal or loan contact, **When** the user asks to modify target amounts, due dates, or status, **Then** the agent executes `goal_update` or `loan_update` and reflects the new state.
3. **Given** an active recurring configuration, **When** the user asks to change the amount, day of month, or pause/cancel the schedule, **Then** the agent executes `recurring_update` or `recurring_delete` safely.

---

### User Story 3 - ReAct Reasoning Loop with Tool Feedback & Pre-condition Validation (Priority: P2)

The AI Agent runs a dynamic Reason-Act-Observe cycle. When an action cannot be completed (e.g. attempting to transfer or spend an amount exceeding the wallet's current balance, or attempting to repay more than the remaining debt), the tool execution returns diagnostic error feedback, allowing the Agent to understand the exact root cause and explain it honestly to the user rather than failing silently.

**Why this priority**: Enhances reliability and user trust by validating financial pre-conditions before committing changes.

**Independent Test**: Have a Cash wallet with 300.000 VND balance $\to$ Say "Chuyển 1 củ từ Tiền mặt sang MoMo" $\to$ Verify the agent detects insufficient funds and responds "Ví Tiền mặt của bạn hiện chỉ còn 300.000đ, không đủ số dư để chuyển 1.000.000đ sang MoMo".

**Acceptance Scenarios**:
1. **Given** a wallet with insufficient balance, **When** a transfer or expense tool is triggered, **Then** the tool returns an error observation and the agent provides an actionable explanation.
2. **Given** a debt repayment attempt exceeding the remaining debt, **When** executed, **Then** the agent caps the debt settlement at zero and notifies the user of the excess amount.

---

### User Story 4 - Multi-Action Batching & Chained Execution (Priority: P2)

Users can express compound financial operations in a single natural language turn (e.g., "Ăn trưa cơm tấm 35k tiền mặt rồi chuyển khoản cho mẹ 2 củ từ VCB", or "Tạo danh mục Nuôi mèo màu cam rồi ghi khoản mua hạt mèo 250k vào đó"). The Agent executes dependent operations sequentially and independent operations in batch.

**Why this priority**: Real-world user speech frequently combines multiple tasks in one sentence.

**Independent Test**: Say "Sáng ăn bún bò 45k rồi chuyển mẹ 2 củ từ VCB" $\to$ Verify both an expense transaction and a transfer/expense transaction are recorded in SQLite simultaneously.

**Acceptance Scenarios**:
1. **Given** a compound prompt with multiple independent transactions, **When** processed, **Then** all corresponding tools execute successfully in one round.
2. **Given** a compound prompt with a dependency (e.g. create category then record transaction in that category), **When** processed in the ReAct loop, **Then** the category is created in Round 1 and the transaction is associated with the newly created `categoryId` in Round 2.

---

### User Story 5 - Instant Generative UI & Fast-Path Navigation (Priority: P3)

Read-only requests (e.g., "hôm nay tao tiêu những gì", "cho xem sổ nợ", "tổng tài sản hiện tại") and screen navigation commands (e.g., "mở cài đặt", "vào sao lưu") bypass multi-round reasoning overhead and immediately render rich interactive cards or perform screen navigation.

**Why this priority**: Guarantees ultra-fast response times (< 400ms) for high-frequency queries.

**Independent Test**: Ask "Hôm nay tao tiêu bao nhiêu rồi?" $\to$ Verify instant generation of Transaction List Card without mutating any database records.

**Acceptance Scenarios**:
1. **Given** a query intent, **When** processed, **Then** the agent dispatches the query tool and attaches the visual `AiViewPayload` card to the assistant message.
2. **Given** a navigation intent, **When** processed, **Then** the agent triggers the onNavigate callback to open the target route immediately.

---

### Edge Cases

- **Slang with mixed units**: e.g., "mua 1 củ 2 trăm rưỡi" correctly parses to 1.250.000 VND.
- **Uncategorized transactions**: When no suitable category exists (e.g., "đổ xăng 50k" without gas category), fallback to "Khác" or leave `categoryId: null` without ever assigning internal system loan categories (`sys_loan_*`).
- **Entity deletion safety**: Deleting a category sets `category_id = NULL` on existing transactions without deleting the transactions themselves.
- **Max loop breaker**: If a ReAct tool loop fails or recurses beyond 4 iterations, the agent halts gracefully and returns the best available summary.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST support a ReAct event-driven loop in Dart (`react_agent.dart`) capable of multi-round reasoning, tool invocation, observation ingestion, and final response generation.
- **FR-002**: System MUST detect missing mandatory parameters in user prompts (e.g., `contactName` for `loan_create`, `targetAmount` for `goal_create`) and issue a clarification question without mutating state.
- **FR-003**: System MUST retain pending intent context across consecutive conversation turns to fulfill multi-turn slot-filling workflows.
- **FR-004**: System MUST provide full CRUD Write Tools for all 7 entity types:
  - Transactions: `transaction_create`, `transaction_update`, `transaction_delete`
  - Wallets: `wallet_create`, `wallet_update`, `wallet_adjust_balance`, `wallet_delete`
  - Categories: `category_create`, `category_update`, `category_delete`
  - Budgets: `budget_set`, `budget_delete`
  - Loans & Debts: `loan_create`, `loan_update`, `loan_delete`, `loan_repay`
  - Saving Goals: `goal_create`, `goal_update`, `goal_delete`, `goal_deposit`, `goal_withdraw`
  - Recurring: `recurring_create`, `recurring_update`, `recurring_delete`
- **FR-005**: System MUST maintain dual-synchronization for loan creations and debt repayments, creating debt ledger records in `loan_transactions` AND corresponding global wallet transactions in `transactions` (`sys_loan_*`).
- **FR-006**: System MUST optimize the System Prompt for Prefix Caching by isolating the 100% invariant static rules prefix (> 1024 tokens) from dynamic timestamp anchors and live database snapshots.
- **FR-007**: System MUST validate financial pre-conditions (such as wallet balances and debt limits) and feed error observations back into the ReAct cycle for clear user feedback.

### Key Entities

- **Transaction**: Monetary cash flow (amount, type: income/expense, categoryId, walletId, date, note).
- **Wallet**: Financial account holding funds (name, type: cash/bank/e_wallet/credit/savings, currentBalance, isDefault).
- **Category**: Spending/Income classification (name, type, icon, color, budgetLimit).
- **MonthlyBudget**: Monthly limit cap for a category or total monthly spend (month: YYYY-MM, categoryId, amount).
- **LoanContact & LoanTransaction**: Debt ledger tracking money owed or lent (contactName, type: lent/borrowed, totalAmount, remainingAmount, dueDate, transactions).
- **SavingGoal**: Financial target (name, targetAmount, currentAmount, targetDate, status).
- **RecurringConfig**: Automated scheduled transaction rule (frequency, interval, dayOfMonth, amount, categoryId, walletId, nextRun, isActive).

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of ambiguous loan/transfer requests trigger a clarifying question without creating orphaned or placeholder records.
- **SC-002**: Multi-action compound prompts with 2 or more actions execute with 100% accuracy in a single conversational turn.
- **SC-003**: ReAct tool observation feedback prevents 100% of silent transaction failures (e.g. overdrafts, invalid IDs).
- **SC-004**: Static prompt prefix achieves 100% Prompt Caching hit rate across turns, reducing Time-to-First-Token (TTFT) by at least 50%.
- **SC-005**: All unit tests for agent tools, protocol parsing, and ReAct workflows pass with 100% success rate.

---

## Assumptions

- The app operates locally with SQLite and calls LLM APIs (e.g., `gpt-5.6-luna`, `gpt-4o-mini`, `gpt-4o`) via configured API keys in `.env`.
- Speech recognition and TTS services are decoupled and interface through the `AiAssistantNotifier` stream.
- In-memory conversation history maintains a bounded 10-message sliding window with complete tool message preservation to stay within context and token budgets.
