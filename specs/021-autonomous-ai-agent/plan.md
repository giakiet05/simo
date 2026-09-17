# Implementation Plan: Autonomous AI Agent with Extensible Tools, Generative UI Cards, and Context Memory

**Branch**: `021-autonomous-ai-agent` | **Date**: 2026-09-17 | **Spec**: [spec.md](./spec.md)

## Summary

Evolve Simo's AI Assistant into a fully decoupled, autonomous 3-tier Agent architecture (`Brain`, `Memory`, `Tools`). 
The Agent will:
1. Support full feature parity with manual UI operations via extensible Write Tools (Transaction CRUD, Wallet creation/adjustment, Budget setting, Goal creation, Recurring schedules).
2. Deliver rich Generative UI Read Tools returning interactive View Cards (`TransactionListCard`, `WalletSummaryCard`, `BudgetProgressCard`, `DebtLedgerCard`, `SavingGoalsCard`).
3. Enforce a 10-turn sliding window working context for fast (< 800ms) multi-turn continuity with a visual `Memory Horizon Divider` in the chat UI.
4. Provide voice/chat driven app navigation (`NavigateScreenTool`).

## Technical Context

**Language/Version**: Dart 3.0+ / Flutter 3.x  
**Primary Dependencies**: `dart_openai` (gpt-4o-mini), `flutter_riverpod`, `flutter_dotenv`, `uuid`  
**Storage**: SQLite (`DatabaseHelper`) + Riverpod State Notifiers  
**Testing**: `flutter test test/unit/`  
**Target Platform**: Android, iOS, Web  
**Project Type**: Mobile Application Subsystem (`apps/mobile/lib/agent/`)  
**Performance Goals**: < 1.0s end-to-end response latency for queries, < 1,200 bounded prompt tokens  
**Constraints**: 100% English codebase, strict JSON object response mode, graceful fallback parsing  

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] Principle 1 (Modularity & Decoupling): Agent core is isolated in `lib/agent/`, decoupled from direct UI bindings.
- [x] Principle 2 (Interface-Driven Tools): All capabilities implement `SimoAgentTool` interface.
- [x] Principle 3 (Test-First & Verifiability): Unit tests cover all tool definitions, protocol parsing, and context sliding buffer.
- [x] Principle 4 (Observability & Structured Logging): Detailed debug logs with context for tool invocations.
- [x] Principle 5 (Simplicity / YAGNI): 10-turn sliding window FIFO chosen over complex LLM rolling summarization.

## Project Structure

### Documentation (this feature)

```text
specs/021-autonomous-ai-agent/
├── plan.md              # This file
├── research.md          # Technical research & decisions
├── data-model.md        # Entities, Tools registry & View Payloads
├── quickstart.md        # Manual verification scenarios
├── contracts/
│   └── agent-tools-protocol.json  # JSON schema contract
└── tasks.md             # Implementation tasks
```

### Source Code Architecture (`apps/mobile/lib/`)

```text
lib/
├── agent/                         # Autonomous Agent Core Module
│   ├── brain/
│   │   ├── agent_brain.dart       # LLM Orchestrator & prompt composer
│   │   ├── system_prompt_builder.dart # Dynamic context & tool injection
│   │   └── protocol_parser.dart   # JSON parsing & fallback handler
│   ├── memory/
│   │   ├── agent_memory_context.dart # 10-turn sliding window buffer
│   │   └── financial_snapshot_builder.dart # Live system state extractor
│   ├── tools/
│   │   ├── agent_tool.dart        # Base SimoAgentTool interface
│   │   ├── tool_registry.dart     # Tool manager & dispatcher
│   │   ├── write/
│   │   │   ├── transaction_tools.dart # Create, Update, Delete transactions
│   │   │   ├── wallet_tools.dart      # Create, Adjust balance, Transfer
│   │   │   ├── budget_tools.dart      # Set/Update monthly budget
│   │   │   ├── loan_tools.dart        # Create loan, Repay loan
│   │   │   ├── goal_tools.dart        # Create, Deposit, Withdraw goals
│   │   │   └── recurring_tools.dart   # Create recurring schedule
│   │   ├── read/
│   │   │   ├── query_transactions_tool.dart
│   │   │   ├── view_wallets_tool.dart
│   │   │   ├── view_budgets_tool.dart
│   │   │   ├── view_debts_tool.dart
│   │   │   └── view_goals_tool.dart
│   │   └── navigation/
│   │       └── navigate_screen_tool.dart # Deep link router
│   ├── ui/
│   │   ├── cards/
│   │   │   ├── ai_transaction_list_card.dart
│   │   │   ├── ai_wallet_summary_card.dart
│   │   │   ├── ai_budget_progress_card.dart
│   │   │   ├── ai_debt_ledger_card.dart
│   │   │   └── ai_saving_goals_card.dart
│   │   └── memory_horizon_divider.dart # Visual context boundary widget
│   └── agent_provider.dart        # Main Riverpod StateNotifier for Agent
├── models/ai_message.dart         # Enriched with AiViewPayload
└── screens/ai_assistant_screen.dart # Full interactive conversational hub
```

## Complexity Tracking

| Decision | Why Needed | Simpler Alternative Rejected Because |
| :--- | :--- | :--- |
| `SimoAgentTool` Interface Registry | Allows adding 15+ actions cleanly without monolithic `switch-case` statements | Monolithic switch-case in one file causes huge regression risks and poor testability |
| 10-Turn Sliding Window FIFO | Enables multi-turn corrections while bounding token cost under 1.2k tokens | Complex LLM summarization adds unnecessary latency, token cost, and potential hallucinations |
