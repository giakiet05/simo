# Technical Research: Autonomous AI Agent Architecture, Extensible Tools, and Generative UI

**Feature**: [spec.md](./spec.md) | **Date**: 2026-09-17

## 1. Architectural Decoupling: Modular Agent Engine

### Decision
Structure the AI Agent as an independent sub-system inside `lib/agent/` following the 3-Tier Agentic Pattern:
- `lib/agent/brain/`: LLM client abstraction (`gpt-4o-mini`), prompt composer, structured output parser.
- `lib/agent/memory/`: 10-turn sliding window working context, memory horizon calculation, local persistence adapter.
- `lib/agent/tools/`: Abstract `SimoAgentTool` interface, Tool Registry, and typed tool definitions.
- `lib/agent/ui/`: Generative UI view cards, chat bubbles, memory horizon divider widget.

### Rationale
- Decouples AI reasoning and tool orchestration from Flutter widget lifecycles and direct repository access.
- Simo Host application acts purely as an environment provider by registering concrete tools (`CreateTransactionTool`, `QueryTransactionsTool`, `SetBudgetTool`, `NavigateScreenTool`) into the Agent's Tool Registry.
- Enables clean unit testing of the Agent Brain and Tools via mocks without needing Flutter widget tests or database setups.

### Alternatives Considered
- *Monolithic Service (`AiTransactionService` with huge switch-cases)*: Hard to maintain, difficult to extend to 15+ actions, high risk of regression on small changes. Rejected in favor of modular `AgentTool` registry.

---

## 2. Extensible Tool Registry & Dynamic Dispatching

### Decision
Implement an interface-driven Tool Registry:
```dart
abstract class SimoAgentTool<TInput, TOutput> {
  String get name;
  String get description;
  Map<String, dynamic> get parametersSchema;
  bool get isDestructive;

  Future<TOutput> execute(TInput input, AgentExecutionContext context);
}
```

### Rationale
- Clean separation of concern: each tool has single responsibility (e.g. `SetBudgetTool` only interacts with `MonthlyBudgetNotifier`).
- The Agent Brain receives tools schema automatically generated from registered tools and instructs the LLM via standard system prompts or function schemas.
- Supports both Write Tools (mutations) and Read Tools (queries returning view models).

---

## 3. Generative UI: Rich Interactive View Cards in Chat

### Decision
Enrich `AiMessage` with an optional `AiViewPayload` representing structured query outputs:
- `TransactionListViewPayload`: List of transactions matching search filters with totals and category metadata.
- `WalletSummaryViewPayload`: Net worth calculation and per-wallet balance breakdown.
- `BudgetProgressViewPayload`: Category budget status, spent vs. limit, % progress bar.
- `DebtLedgerViewPayload`: Categorized receivables and payables with debtor names.
- `SavingGoalsViewPayload`: Saving targets, accumulated amounts, and completion percentages.

### Rationale
- Visual cards provide 10x better UX than plain text walls.
- Every card item contains a deep link tap handler that pushes the relevant detail screen (`TransactionDetail`, `WalletDetail`, `BudgetSettings`).

---

## 4. Working Memory & Visual Horizon Divider

### Decision
- **Sliding Buffer**: Keep exactly the last 10 conversational turns (5 user messages, 5 assistant replies) in the active working context payload sent to `gpt-4o-mini`.
- **Memory Horizon Divider**: In the chat list view, if the total message count exceeds 10, dynamically render a sticky/inline divider widget (`──── 🧠 AI ghi nhớ từ đây (10 tin gần nhất) ────`) immediately preceding the 10th most recent message.
- **Token Bounds**: Prompt size remains strictly bounded under 1,200 tokens, maintaining ultra-fast response latency (< 800ms) and minimal OpenAI cost.

---

## 5. Navigation Tool & Deep Linking

### Decision
Implement `NavigateScreenTool` taking destination parameter (`dashboard`, `budgets`, `reports`, `wallets`, `loans`, `goals`, `export_backup`, `settings`, `categories`).
- The Agent execution context holds a navigation callback or `BuildContext`/`GlobalKey<NavigatorState>` to smoothly push the targeted screen.
