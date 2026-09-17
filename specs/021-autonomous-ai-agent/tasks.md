# Tasks: Autonomous AI Agent with Extensible Tools, Generative UI Cards, and Context Memory

**Feature**: [spec.md](./spec.md) | **Plan**: [plan.md](./plan.md)

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic directory structure

- [x] T001 Create agent directory structure (`apps/mobile/lib/agent/brain/`, `apps/mobile/lib/agent/memory/`, `apps/mobile/lib/agent/tools/`, `apps/mobile/lib/agent/ui/`)

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core agent interfaces, memory context, and brain orchestration that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [x] T002 [P] Define `SimoAgentTool` interface and execution context in `apps/mobile/lib/agent/tools/agent_tool.dart`
- [x] T003 [P] Implement `ToolRegistry` for registering and dispatching tools in `apps/mobile/lib/agent/tools/tool_registry.dart`
- [x] T004 [P] Implement `AgentMemoryContext` with 10-turn sliding window FIFO buffer in `apps/mobile/lib/agent/memory/agent_memory_context.dart`
- [x] T005 [P] Implement `FinancialSnapshotBuilder` for live state extraction in `apps/mobile/lib/agent/memory/financial_snapshot_builder.dart`
- [x] T006 Implement `SystemPromptBuilder` with tool schema injection in `apps/mobile/lib/agent/brain/system_prompt_builder.dart`
- [x] T007 Implement `ProtocolParser` with strict JSON parsing and raw text fallback in `apps/mobile/lib/agent/brain/protocol_parser.dart`
- [x] T008 Implement `AgentBrain` orchestrator connecting OpenAI client (`gpt-4o-mini`) with prompt builder and parser in `apps/mobile/lib/agent/brain/agent_brain.dart`

**Checkpoint**: Foundation ready - Agent core is decoupled and ready for tool integration.

---

## Phase 3: User Story 1 - Interactive Generative UI Data View Cards (Priority: P1) 🎯 MVP

**Goal**: Enable users to view financial data (transactions, wallets, budgets, debts, saving goals) via natural language and receive rich interactive cards in chat.

**Independent Test**: Ask "Cho tao xem các khoản chi hôm nay" or "Cho tao xem số dư các ví" and verify the assistant renders interactive structured cards (`AiTransactionListCard`, `AiWalletSummaryCard`) with clickable item links.

### Implementation for User Story 1

- [x] T009 [P] [US1] Define `AiViewPayload` and concrete view items in `apps/mobile/lib/models/ai_message.dart`
- [x] T010 [P] [US1] Implement `QueryTransactionsTool` in `apps/mobile/lib/agent/tools/read/query_transactions_tool.dart`
- [x] T011 [P] [US1] Implement `ViewWalletsTool` in `apps/mobile/lib/agent/tools/read/view_wallets_tool.dart`
- [x] T012 [P] [US1] Implement `ViewBudgetsTool` in `apps/mobile/lib/agent/tools/read/view_budgets_tool.dart`
- [x] T013 [P] [US1] Implement `ViewDebtsTool` in `apps/mobile/lib/agent/tools/read/view_debts_tool.dart`
- [x] T014 [P] [US1] Implement `ViewGoalsTool` in `apps/mobile/lib/agent/tools/read/view_goals_tool.dart`
- [x] T015 [P] [US1] Build `AiTransactionListCard` in `apps/mobile/lib/agent/ui/cards/ai_transaction_list_card.dart`
- [x] T016 [P] [US1] Build `AiWalletSummaryCard` in `apps/mobile/lib/agent/ui/cards/ai_wallet_summary_card.dart`
- [x] T017 [P] [US1] Build `AiBudgetProgressCard` in `apps/mobile/lib/agent/ui/cards/ai_budget_progress_card.dart`
- [x] T018 [P] [US1] Build `AiDebtLedgerCard` in `apps/mobile/lib/agent/ui/cards/ai_debt_ledger_card.dart`
- [x] T019 [P] [US1] Build `AiSavingGoalsCard` in `apps/mobile/lib/agent/ui/cards/ai_saving_goals_card.dart`
- [x] T020 [US1] Update `AiMessageBubble` in `apps/mobile/lib/widgets/ai/ai_message_bubble.dart` to render view payload cards with item tap handlers

**Checkpoint**: At this point, User Story 1 is fully functional and testable independently (MVP ready!).

---

## Phase 4: User Story 2 - Full Financial Mutation Tool Calling (Priority: P1)

**Goal**: Enable users to execute all write operations (creating/adjusting wallets, setting monthly budgets, creating goals, recurring schedules, and deleting/updating transactions) via voice or chat.

**Independent Test**: Issue voice/text commands for setting a budget ("Đặt ngân sách ăn uống 3 triệu") or creating a wallet ("Tạo ví MB Bank 5 triệu") and verify state persistence and visual confirmation cards.

### Implementation for User Story 2

- [x] T021 [P] [US2] Implement `TransactionTools` (create, update, delete) in `apps/mobile/lib/agent/tools/write/transaction_tools.dart`
- [x] T022 [P] [US2] Implement `WalletTools` (create, adjust balance, transfer) in `apps/mobile/lib/agent/tools/write/wallet_tools.dart`
- [x] T023 [P] [US2] Implement `BudgetTools` (set/update monthly budget) in `apps/mobile/lib/agent/tools/write/budget_tools.dart`
- [x] T024 [P] [US2] Implement `LoanTools` (create loan, repay loan) in `apps/mobile/lib/agent/tools/write/loan_tools.dart`
- [x] T025 [P] [US2] Implement `GoalTools` (create goal, deposit, withdraw) in `apps/mobile/lib/agent/tools/write/goal_tools.dart`
- [x] T026 [P] [US2] Implement `RecurringTools` (create scheduled rule) in `apps/mobile/lib/agent/tools/write/recurring_tools.dart`
- [x] T027 [US2] Register mutation tools into `ToolRegistry` and hook with Simo Riverpod providers in `apps/mobile/lib/providers/ai_assistant_provider.dart`

**Checkpoint**: At this point, User Stories 1 AND 2 are fully integrated and functional.

---

## Phase 5: User Story 3 - 10-Turn Working Context Memory & Horizon Divider (Priority: P2)

**Goal**: Enable multi-turn conversational continuity (corrections, follow-ups) with an explicit visual boundary indicator in the chat stream.

**Independent Test**: Chat for > 10 messages, verify the visual divider appears above the 10th recent turn, and issue a follow-up correction referencing the immediate previous turn.

### Implementation for User Story 3

- [x] T028 [P] [US3] Build `MemoryHorizonDivider` widget in `apps/mobile/lib/agent/ui/memory_horizon_divider.dart`
- [x] T029 [US3] Update `AiAssistantNotifier` in `apps/mobile/lib/providers/ai_assistant_provider.dart` to calculate horizon index and maintain 10-turn sliding buffer
- [x] T030 [US3] Update `AiAssistantScreen` in `apps/mobile/lib/screens/ai_assistant_screen.dart` to dynamically render `MemoryHorizonDivider` above message index `total - 10`

**Checkpoint**: At this point, working memory context is fully transparent and multi-turn corrections work accurately.

---

## Phase 6: User Story 4 - App Navigation Deep Linking (Priority: P3)

**Goal**: Enable users to navigate to specific app screens (Reports, Export, Wallets, Budgets) via voice or chat.

**Independent Test**: Say "Mở màn hình báo cáo thống kê" or "Dẫn vào sao lưu" and verify immediate route transition.

### Implementation for User Story 4

- [x] T031 [P] [US4] Implement `NavigateScreenTool` in `apps/mobile/lib/agent/tools/navigation/navigate_screen_tool.dart`
- [x] T032 [US4] Register `NavigateScreenTool` with app navigator callback in `apps/mobile/lib/providers/ai_assistant_provider.dart`

**Checkpoint**: All 4 user stories are functional.

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Verification, tests, and final cleanup

- [x] T033 [P] Add comprehensive unit tests in `apps/mobile/test/unit/agent_tools_test.dart` verifying all tools and sliding window context
- [x] T034 Run `flutter test` and `flutter analyze` to ensure 0 errors and 0 lint warnings
- [x] T035 Validate end-to-end quickstart scenarios in `specs/021-autonomous-ai-agent/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately.
- **Foundational (Phase 2)**: Depends on Setup completion - BLOCKS all user stories.
- **User Story 1 (Phase 3)**: Depends on Foundational. MVP release!
- **User Story 2 (Phase 4)**: Depends on Foundational & US1 models.
- **User Story 3 (Phase 5)**: Depends on Foundational.
- **User Story 4 (Phase 6)**: Depends on Foundational.
- **Polish (Phase 7)**: Depends on all user stories being complete.

---

## Implementation Strategy

### MVP First (User Story 1 Only)
1. Complete Phase 1: Setup
2. Complete Phase 2: Foundational (Decoupled Agent Brain + Memory + Tool Registry)
3. Complete Phase 3: User Story 1 (Generative UI View Cards)
4. Validate MVP: Ask AI to view transactions, wallets, budgets, debts, and goals.

### Incremental Delivery
1. Phase 1 + 2: Core Foundation Ready
2. Phase 3: Generative UI Read Cards (MVP)
3. Phase 4: Full Financial Mutation Tools (100% App Feature Parity)
4. Phase 5: 10-Turn Context Window & Horizon Divider
5. Phase 6: App Navigation Deep Linking
6. Phase 7: Automated Tests & Validation
