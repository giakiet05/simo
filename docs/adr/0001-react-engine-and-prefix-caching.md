# ADR-0001: Adopt Pure-Dart ReAct Engine, Multi-Turn Slot Filling, and 3-Tier Prefix-Cached Prompts for AI Financial Agent

## Status

Accepted

## Context

The initial implementation of the Simo AI Assistant (`apps/mobile/lib/agent/`) relied on a single-turn blind JSON extraction flow. The application sent the user's message alongside dynamic financial context to an LLM, expecting a JSON action structure in return. 

This legacy approach presented several critical limitations:
1. **Hallucination on Ambiguity**: When the user provided incomplete information (e.g., *"Lend 200k to a friend"* without specifying who), the LLM frequently hallucinated default values (such as person name *"Người quen"* or arbitrary categories) rather than clarifying.
2. **Lack of Observation Feedback**: The agent could not observe tool execution results. When a database operation failed or returned unexpected data, the agent could not self-correct, retry, or formulate a helpful error explanation.
3. **Multi-Step Execution Gap**: Complex user intents requiring sequential dependencies (e.g., creating a new category before recording an expense, or checking wallet balance before transferring) could not be orchestrated.
4. **Poor Cache Utilization**: Dynamic timestamps (`$now`) and database snapshots placed near the top/middle of the system prompt invalidated LLM prompt caching (OpenAI / `gpt-5.6-luna`), resulting in high Time-to-First-Token (TTFT) latency (>1.5s) and unnecessary token costs.
5. **Incomplete CRUD Coverage**: Only transaction/category creation and basic queries were supported, leaving wallets, debts, budgets, goals, and recurring rules without update/delete tooling.

We needed an architecture that guarantees deterministic tool calling, observation feedback, conversational slot-filling for missing parameters, and optimal prefix caching latency.

## Decision Drivers

* **Zero Hallucinated Financial Actions**: Crucial financial records (debts, transfers, expenses) must never be created with made-up parameters.
* **Resilient Multi-Round Orchestration**: Ability to reason, act, observe tool outputs, and provide natural explanations or self-corrections.
* **Low Latency & High Responsiveness**: Optimize for prompt prefix caching (>1024 tokens static prefix) on modern models (`gpt-5.6-luna`, `gpt-4o`).
* **Minimal Dependency Overhead**: Avoid bloated third-party agent frameworks (e.g., LangChain Dart, LangGraph) to keep mobile bundle size small and maintenance strictly under our control.
* **Offline-First Storage Integrity**: Maintain dual-synchronization between domain-specific accounting (e.g. loans/debts) and general wallet cash flows.

## Considered Options

### Option 1: Integrate LangChain Dart / LangGraph Dart
- **Pros**: Off-the-shelf abstractions for agent loops and tool calling.
- **Cons**: Adds large external dependencies to Flutter, introduces unneeded abstractions, has slower maintenance cycles in Dart ecosystem, and complicates custom prompt caching optimization.

### Option 2: Keep Single-Turn JSON Extraction with Rigid Frontend Validation
- **Pros**: Simplest code structure; no multi-round network calls.
- **Cons**: Cannot support multi-step tool dependencies; unable to feed tool errors back to LLM for diagnostic explanations; fragile regex/JSON parsing.

### Option 3 (Chosen): Port Pure-Dart Event-Driven ReAct Engine from `uit-hub` with 3-Tier Prefix-Cached Prompts
- **Pros**:
  - **Proven Architecture**: Successfully validated in production backend (`uit-hub`).
  - **Zero Heavy Dependencies**: Implemented in clean, modern Dart using standard streams, records, and `dart_openai`.
  - **3-Tier Prefix Prompt Caching**: Static role/tool schemas (>1400 tokens) placed at token index 0 guarantees >50% TTFT reduction and 50% API cost reduction.
  - **Multi-Turn Slot-Filling**: Explicit prohibition of guessing + `PendingIntentState` machine stops and asks the user for missing slots, then resumes deterministically.
  - **Full Observation Feedback**: Tool execution results and diagnostic errors are returned into the loop for self-correcting explanations.
- **Cons**:
  - Multi-round agent turns may require multiple LLM calls (bounded by `maxRounds = 4`).

## Decision

We decided to adopt **Option 3**:
1. Build a pure Dart **ReAct Execution Engine** (`react_agent.dart`) implementing an event-driven `Reason -> Act -> Observe -> Reason` loop yielding typed `AgentEvent` streams (`RoundStarted`, `ModelCall`, `ToolExecution`, `FinalAnswer`).
2. Implement **3-Tier System Prompt Caching**:
   - `Tier 1 (StaticPart)`: Role definition, strict ambiguity rules, VND slang dictionary, few-shot examples, and tool calling guidelines (>1024 tokens, 100% cacheable).
   - `Tier 2 (DynamicPart)`: Live financial database snapshot (wallets, categories, debts, goals, budgets).
   - `Tier 3 (UncachedPart)`: Current ISO-8601 timestamp `$now`.
3. Introduce **`PendingIntentState`** in `AiAssistantState` to manage multi-turn slot-filling when required parameters are missing.
4. Expand the agent tool registry to provide **Full CRUD coverage** across all 7 domain entities (Transactions, Wallets, Categories, Budgets, Loans/Debts, Saving Goals, Recurring Payments).
5. Enforce **Dual-Accounting Synchronization** for loan operations to automatically maintain wallet cash flows with `sys_loan_*` categories.

## Consequences

### Positive
- **Deterministic Clarification**: Missing loan borrower names, transfer destination wallets, or category names trigger direct conversational questions instead of silent guesswork.
- **High Performance**: Prompt caching hits on Tier 1 yield TTFT < 300ms on `gpt-5.6-luna`.
- **Diagnostic Transparency**: SQLite constraints or balance validation errors are observed by the LLM and communicated in clear, friendly Vietnamese.
- **Clean Architecture**: Decoupled tool execution, pure Dart engine, and seamless Riverpod UI state management.

### Negative & Mitigations
- **Network Roundtrips**: Multi-step operations (e.g. creating category then transaction) make 2 LLM rounds.
  - *Mitigation*: Batch parallel tool execution within each round, and limit maximum rounds to 4.
- **State Complexity**: Managing multi-turn pending intent across dialogue turns.
  - *Mitigation*: Encapsulate state transition logic in an immutable `PendingIntentState` class with clear expiration policies.

## Related Artifacts
- **Feature Spec**: [`specs/022-react-agent-full-crud/spec.md`](../../specs/022-react-agent-full-crud/spec.md)
- **Implementation Plan**: [`specs/022-react-agent-full-crud/plan.md`](../../specs/022-react-agent-full-crud/plan.md)
- **Research & Analysis**: [`specs/022-react-agent-full-crud/research.md`](../../specs/022-react-agent-full-crud/research.md)
- **Tool Contracts**: [`specs/022-react-agent-full-crud/contracts/agent_tools.json`](../../specs/022-react-agent-full-crud/contracts/agent_tools.json)
