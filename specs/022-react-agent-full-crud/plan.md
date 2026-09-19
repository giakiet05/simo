# Implementation Plan: ReAct AI Agent Architecture with Full CRUD & Multi-turn Clarification

**Branch**: `022-react-agent-full-crud` | **Date**: 2026-09-19 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/022-react-agent-full-crud/spec.md`

## Summary

Refactor the Simo Autonomous AI Financial Agent from a single-turn blind JSON extraction architecture into a robust, event-driven **ReAct (Reasoning + Acting + Observation Feedback)** agent in Dart (ported from the proven architecture in `uit-hub`). 
Key deliverables:
1. Pure Dart **ReAct Execution Engine** (`react_agent.dart`) supporting multi-round tool calling, observation ingestion, and self-correcting explanations.
2. **Multi-turn Clarification & Slot-Filling State Machine** (`PendingIntentState`) preventing hallucinated defaults on ambiguous inputs.
3. Complete **Full CRUD Toolset** across all 7 domain entities (Transactions, Wallets, Categories, Budgets, Loans, Goals, Recurring).
4. **3-Tier Prefix Caching System Prompt** (`StaticPart` > 1024 tokens + `DynamicPart` snapshot + `UncachedPart` timestamp anchor) delivering >50% lower TTFT latency on `gpt-5.6-luna`.

---

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x (Modern Dart sound null-safety, records, pattern matching)

**Primary Dependencies**: `flutter_riverpod`, `dart_openai`, `uuid`, `sqflite`, `flutter_dotenv`

**Storage**: Local SQLite via `DatabaseHelper` and Riverpod state notifiers

**Testing**: `flutter test` (Unit & Widget tests for agent tools, protocol parser, ReAct loops)

**Target Platform**: Android, iOS, Desktop/Web (100% Linux ecosystem dev environment)

**Project Type**: Mobile Application (Offline-first client with direct LLM gateway)

**Performance Goals**: Time-to-First-Token (TTFT) < 300ms with prompt caching; multi-round loop completion < 1.2s on `gpt-5.6-luna`

**Constraints**: Offline-first financial storage, strict prompt caching preservation (> 1024 tokens prefix), zero hallucinated financial transactions

---

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] 100% English codebase (code, symbols, logs, commits)
- [x] No emoji/icons in code, comments, logs, or commit messages
- [x] Standard library / minimal dependency discipline (no heavy LangChain/LangGraph Dart packages)
- [x] Structured error handling (no silent failures or swallowed exceptions)
- [x] Automated test suite coverage for all new write tools and ReAct execution loops
- [x] Zero secrets policy (only `.env.example` committed)

---

## Project Structure

### Documentation (this feature)

```text
specs/022-react-agent-full-crud/
├── plan.md              # Implementation Plan
├── research.md          # Architectural research & decisions
├── data-model.md        # State models, pending intent, tool results
├── quickstart.md        # Verification & test execution guide
├── contracts/
│   └── agent_tools.json # OpenAI Tool Calling function schemas
└── checklists/
    └── requirements.md  # Spec quality validation checklist
```

### Source Code Layout

```text
apps/mobile/lib/
├── agent/
│   ├── engine/
│   │   ├── react_agent.dart          # [NEW] ReAct Reason-Act-Observe Execution Loop
│   │   └── agent_event.dart          # [NEW] Event stream (RoundStarted, ToolCall, FinalAnswer)
│   ├── brain/
│   │   ├── agent_brain.dart          # Central LLM client integration
│   │   ├── tool_specs.dart           # [NEW] OpenAI Tool Definition schemas
│   │   ├── system_prompt_builder.dart# 3-Tier Prefix-Cached System Prompt Builder
│   │   └── protocol_parser.dart      # Standardized tool call and text response parser
│   ├── memory/
│   │   ├── agent_memory_context.dart # Dialogue history with complete tool message preservation
│   │   ├── pending_intent_state.dart # [NEW] Slot-filling & clarification state
│   │   └── financial_snapshot_builder.dart # Live database context builder
│   ├── tools/
│   │   ├── agent_tool.dart           # Base tool contract & execution context
│   │   ├── tool_registry.dart        # Central registry & dispatcher
│   │   ├── write/
│   │   │   ├── transaction_tools.dart# create, update, delete
│   │   │   ├── wallet_tools.dart     # create, update [NEW], adjust, delete [NEW], transfer
│   │   │   ├── category_tools.dart   # create, update, delete
│   │   │   ├── budget_tools.dart     # set, delete [NEW]
│   │   │   ├── loan_tools.dart       # create, update [NEW], delete [NEW], repay
│   │   │   ├── goal_tools.dart       # create, update [NEW], delete [NEW], deposit, withdraw
│   │   │   └── recurring_tools.dart  # create, update [NEW], delete [NEW]
│   │   ├── read/                     # query_transactions, view_wallets, view_budgets, view_debts, view_goals
│   │   └── navigation/              # navigate_screen
│   └── ui/                           # Generative UI Cards
├── providers/
│   └── ai_assistant_provider.dart    # Riverpod notifier coordinating ReAct stream & UI state
└── services/
    └── ai_action_dispatcher.dart     # Legacy/direct batch fallback dispatcher
```

---

## Complexity Tracking

*No constitution violations.* Clean modular port of ReAct engine using pure Dart primitives and existing Riverpod providers.
