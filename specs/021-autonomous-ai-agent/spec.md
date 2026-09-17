# Feature Specification: Autonomous AI Agent with Extensible Tools, Generative UI Cards, and Context Memory

**Feature Branch**: `021-autonomous-ai-agent`

**Created**: 2026-09-17

**Status**: Draft

**Input**: User description: "tăng cường thêm tính năng cho AI da dạng hơn. có thể làm mọi thứ trong simo luôn được ko? mấy cái nào người dùng bấm được là simo assitant làm dc hết? cho nó xem luôn dc ko? cấu trúc 3 phần Não - Bộ nhớ (max 10 turn, vạch ngăn cách bộ nhớ) - Tool calling, tách riêng module."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Interactive Generative UI Data View Cards (Priority: P1)

As a Simo user, I want to ask the AI assistant to display my financial data (transactions, wallets, budgets, debts, saving goals) using natural language, so that I receive interactive, visual cards directly in the chat without having to navigate to separate screens.

**Why this priority**: Immediate data retrieval and visualization is the most frequent use case for a personal financial assistant. It transforms the AI from a simple command recorder into a comprehensive financial dashboard assistant.

**Independent Test**: Can be tested by asking "Cho tao xem hôm nay tiêu những gì?" or "Cho tao xem số dư các ví", and verifying that the assistant renders interactive structured cards (`AiDataViewCard`) with live data and clickable item links.

**Acceptance Scenarios**:
1. **Given** the user has recorded expenses today, **When** the user says "Cho tao xem các khoản chi hôm nay", **Then** the assistant responds with a summary text and renders an interactive `TransactionListCard` displaying each transaction's category icon, amount, note, wallet, and time.
2. **Given** the user has multiple wallets, **When** the user says "Cho tao xem số dư các ví", **Then** the assistant renders a `WalletSummaryCard` showing total net worth and individual wallet balances with direct navigation links.
3. **Given** the user has active monthly budgets, **When** the user says "Cho tao xem ngân sách tháng này", **Then** the assistant renders a `BudgetProgressCard` with colored progress bars (safe/warning/exceeded) and remaining spending allowances.
4. **Given** the user has lending/borrowing contacts, **When** the user says "Ai đang nợ tiền tao?", **Then** the assistant filters and displays a `DebtLedgerCard` listing debtor names, remaining balances, and quick settlement buttons.
5. **Given** any data card in chat, **When** the user taps an item within the card, **Then** the app navigates directly to the corresponding management or detail screen.

---

### User Story 2 - Full Financial Mutation Tool Calling (Priority: P1)

As a Simo user, I want the AI assistant to execute all write operations available in Simo (creating/adjusting wallets, setting monthly budgets, creating saving goals, scheduling recurring payments, and deleting/updating transactions), so that I can manage my entire financial lifecycle via voice or chat.

**Why this priority**: Complete feature parity with manual user interface operations enables a true "hands-free" autonomous agent experience.

**Independent Test**: Can be tested by issuing voice/text commands for setting a budget ("Đặt ngân sách ăn uống 3 triệu"), creating a new wallet ("Tạo ví mới MB Bank số dư 5 triệu"), or deleting a transaction, and verifying database persistence and visual confirmation cards.

**Acceptance Scenarios**:
1. **Given** the user wants to set a category budget, **When** the user says "Đặt ngân sách ăn uống tháng này là 3 triệu", **Then** the assistant executes the `budget_set` tool and renders a confirmation card with the updated budget status.
2. **Given** the user opened a new bank account, **When** the user says "Tạo ví mới tên MB Bank số dư 5 triệu", **Then** the assistant executes the `wallet_create` tool and confirms the new wallet creation.
3. **Given** the user adjusted physical cash, **When** the user says "Sửa số dư ví tiền mặt thành 300k", **Then** the assistant executes `wallet_adjust_balance` tool and reports the balance adjustment.
4. **Given** a recurring monthly commitment, **When** the user says "Tạo lịch đóng tiền trọ 3.5 triệu vào ngày 5 hàng tháng", **Then** the assistant executes `recurring_create` tool and displays scheduled details.
5. **Given** a destructive operation (e.g., deleting a transaction or large adjustment), **When** triggered, **Then** the assistant presents a confirmation prompt before executing or allows instant 1-tap undo.

---

### User Story 3 - 10-Turn Working Context Memory with Visual Horizon Divider (Priority: P2)

As a Simo user, I want the AI assistant to maintain a rolling memory of the last 10 conversation turns in the current session and visually show me where its memory begins, so that I can issue follow-up commands and corrections seamlessly while clearly understanding what the AI remembers.

**Why this priority**: Eliminates ambiguity during multi-step tasks (e.g., "Sửa khoản vừa rồi thành 50k", "À trừ từ ví Momo mới đúng") while providing complete explainability to the user.

**Independent Test**: Can be tested by initiating a conversation of > 10 turns, verifying the visual divider is positioned above the 10th most recent message, and issuing a follow-up correction referencing the immediate previous turn.

**Acceptance Scenarios**:
1. **Given** a conversation with more than 10 messages, **When** the user views the chat screen, **Then** a clean visual divider labeled `──── 🧠 AI ghi nhớ từ đây (10 tin gần nhất) ────` appears dynamically above the 10th most recent message.
2. **Given** the user just recorded a transaction in Turn N, **When** the user immediately says in Turn N+1 "À sửa ví nguồn thành Momo nhé", **Then** the assistant correctly resolves the reference to Turn N and updates the transaction.
3. **Given** messages older than 10 turns, **When** context is constructed for the AI, **Then** older messages are retained in local UI history for user scrolling but automatically omitted from the LLM prompt payload to preserve low latency and bounded token cost.

---

### User Story 4 - App Navigation & Deep Linking via Chat (Priority: P3)

As a Simo user, I want to ask the AI to open specific screens in the app (Reports/Analytics, Export Excel, Backup & Sync, Category Management), so that I can quickly navigate without searching through menus.

**Why this priority**: Enhances accessibility and navigation speed for users who prefer natural language over tapping through nested tab bars and menus.

**Independent Test**: Can be tested by saying "Mở màn hình báo cáo thống kê" or "Dẫn tao tới xuất file Excel", and verifying that the app pushes the correct route immediately.

**Acceptance Scenarios**:
1. **Given** the user is in the AI Assistant screen, **When** the user says "Mở màn hình thống kê chi tiêu", **Then** the assistant acknowledges with a friendly reply and smoothly navigates the user to the Analytics/Dashboard screen.
2. **Given** the user wants to backup or export, **When** the user says "Dẫn tao vào phần Cài đặt sao lưu", **Then** the assistant navigates directly to the `ExportBackupScreen`.

---

### Edge Cases

- **Ambiguous query ("Cho tao xem tiền")**: Assistant asks a clarifying question or shows the top-level net worth and wallet balances by default.
- **Referencing outside memory bound**: If the user says "Xóa khoản tao thêm 3 ngày trước" (which is outside the 10-turn window), the assistant queries the database via filter/search rather than relying on conversation memory, or prompts the user for specific details.
- **Empty query results**: If user asks "Cho tao xem các khoản chi du lịch tuần này" and there are 0 records, the card displays a friendly empty state ("Không có giao dịch nào phù hợp trong tuần này") instead of failing.
- **Offline / Network failure**: If offline, the assistant informs the user and retains local chat state safely.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST decouple the AI Agent architecture into three distinct layers: Brain (LLM Orchestrator & Prompt Builder), Memory Engine (Sliding Context & Persistence), and Tool Registry (Interface-based Tool Executors).
- **FR-002**: System MUST implement Read/Query Tools that fetch and format local database entities: `query_transactions`, `view_wallets`, `view_budgets`, `view_debts`, `view_goals`.
- **FR-003**: System MUST render specialized Generative UI cards in the chat stream for each query type: `TransactionListCard`, `WalletSummaryCard`, `BudgetProgressCard`, `DebtLedgerCard`, and `SavingGoalsCard`.
- **FR-004**: System MUST implement Write/Mutation Tools: `budget_set`, `wallet_create`, `wallet_adjust_balance`, `goal_create`, `recurring_create`, `transaction_delete`, and `transaction_update`.
- **FR-005**: System MUST implement a Navigation Tool (`navigate_screen`) supporting destinations: `dashboard`, `reports`, `wallets`, `budgets`, `loans`, `goals`, `export_backup`, `settings`, `categories`.
- **FR-006**: System MUST maintain a sliding window of exactly 10 recent conversation turns (5 User turns, 5 Assistant turns) when constructing the prompt context for the LLM.
- **FR-007**: System MUST render a visual `Memory Horizon Divider` above the oldest active working memory message whenever total chat history exceeds 10 turns.
- **FR-008**: System MUST persist all conversation messages locally so that full historical dialogue remains accessible across app restarts.
- **FR-009**: System MUST provide an interactive 1-tap Clear Chat button that resets the working memory and clears the active session.
- **FR-010**: All UI cards rendered in chat MUST support interactive tap gestures to navigate to their corresponding entity detail screen.
- **FR-011**: System MUST strictly enforce JSON Structured Outputs (`response_format: {"type": "json_object"}`) on all LLM requests with graceful fallback parsing.
- **FR-012**: Destructive operations MUST provide either an inline confirmation UI or an immediate undo capability.

### Key Entities

- **AgentTool**: Interface defining tool metadata (name, description, parameters schema, destructive flag) and execution logic.
- **AiMessage**: Core conversational unit enriched with support for both `AiExecutedAction` (mutations) and `AiViewPayload` (query results & card representations).
- **AiViewPayload**: Structured data container holding typed query results for inline Generative UI card rendering (transactions, wallets, budgets, loans, goals).
- **AgentMemoryContext**: Working state containing the 10-turn sliding buffer, live financial snapshot, and memory horizon index.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of core Simo features (Transactions, Wallets, Budgets, Loans, Goals, Recurring, Navigation) can be executed via voice or text through the AI Assistant.
- **SC-002**: Queries matching "Cho tao xem..." render interactive visual data cards within 1.5 seconds under normal network conditions.
- **SC-003**: Follow-up multi-turn commands within the 10-turn window achieve at least 95% accuracy in entity reference resolution.
- **SC-004**: Average prompt token usage remains bounded under 1,500 tokens per request regardless of total conversation length.
- **SC-005**: 0% application crashes on unexpected LLM responses due to strict schema validation and graceful fallback handling.

## Assumptions

- Target LLM is `gpt-4o-mini` (or OpenAI-compatible fast model) supporting JSON object response format.
- Users have local database records (SQLite via existing Simo repositories) available on the device.
- All actions respect the user's primary currency (VND) with standard colloquial multipliers.
