# Research & Technical Decisions: Conversational AI Financial Assistant & Agent

**Feature**: `020-ai-assistant-agent`  
**Date**: 2026-09-17  
**Status**: Approved  

---

## 1. AI Provider & Model Architecture

### Decision
Migrate primary AI service integration from Groq (`llama-3.3-70b-versatile`) to **OpenAI API** (`https://api.openai.com/v1`) using **`gpt-5-nano`** as the default model, while preserving environment configuration overrides (`AI_BASE_URL`, `AI_API_KEY`, `AI_MODEL`).

### Rationale
- **`gpt-5-nano` Performance & Speed**: Designed specifically for high-throughput, low-latency agentic workflows and instruction following. It parses Vietnamese conversational expressions and currency slang rapidly (<1s generation time) with low token cost.
- **Strict Adherence to JSON / Schema Constraints**: OpenAI models support rock-solid JSON mode and deterministic structured output parsing, avoiding the formatting halluncinations occasionally observed with open-weight endpoints.
- **Provider Standardization**: Leverages the official OpenAI standard format. Dart's `dart_openai` (already in `pubspec.yaml`) natively targets this exact API specification without adding third-party dependencies.

### Alternatives Considered
| Provider / Model | Latency | JSON Reliability | Cost | Verdict |
| :--- | :--- | :--- | :--- | :--- |
| **Groq (Llama-3.3-70b)** | ~400ms | Moderate (occasional markdown wrapper leaks) | Low / Free Tier | **Replaced**: User requested migration away from Groq. |
| **OpenAI GPT-4o-mini** | ~800ms | High | Low | **Alternative**: Solid, but superseded by newer nano-tier architecture. |
| **OpenAI GPT-5-nano** | ~500ms | Extremely High | Ultra-Low | **Selected**: Optimal balance of speed, cost, and agent reasoning. |

---

## 2. Speech-to-Text (STT) Pipeline Standardization

### Decision
Direct `WhisperSpeechService` to OpenAI Whisper API (`https://api.openai.com/v1/audio/transcriptions`) using `whisper-1`, while preserving fallback to `LocalSpeechToTextService` when offline or when `USE_WHISPER=false`.

### Rationale
- **Vietnamese Slang Context Prompting**: OpenAI Whisper accepts a `prompt` field providing vocabulary hints ("k", "cành", "củ", "lít", "xị", "chục", "Techcombank", "MoMo"). This drastically reduces acoustic misinterpretation on colloquial terms.
- **AAC/M4A Efficiency**: Flutter's `record` package produces lightweight `.m4a` audio files (~20-50KB for a 5-second voice snippet), uploaded in milliseconds.

---

## 3. Agentic Interaction Pattern: Dual-Output Structured Protocol

### Decision
Implement a **Single-Round Dual-Output Structured Protocol** where the LLM produces:
1. `responseMessage`: A polite, human-like Vietnamese conversational response to the user.
2. `thought`: Internal reasoning chain bóc tách logic.
3. `isActionRequired`: Boolean indicating if mutation operations are present.
4. `actions`: Array of executable mutations (`transaction`, `transfer`, `loan_create`, `loan_repay`, `goal_deposit`, `goal_withdraw`).

### Rationale
- **Mobile Latency Optimization**: Multi-step Function Calling (Model $\to$ Call Tool $\to$ Tool Result $\to$ Model $\to$ Final Text) on mobile networks introduces 2-3 roundtrips (3-6 seconds latency). The single-round dual-output pattern achieves instant execution and response in under 2 seconds.
- **Seamless Financial Q&A vs Mutation**: If the user asks *"Hôm nay tao tiêu gì?"*, `actions` is empty, and `responseMessage` answers the query directly using injected financial context. If the user commands *"Ăn trưa 40k"*, `actions` contains the transaction, and `responseMessage` confirms it.

---

## 4. Financial Context Injection & Safety Guardrails

### Decision
Before querying the LLM, the client aggregates a lightweight snapshot of current financial state:
- Available Wallets (names, types, current balances)
- Categories (names, income/expense classification)
- Active Loan Contacts (debtors/creditors, remaining amounts)
- Saving Goals (names, target vs accumulated amounts)
- Today's Cash Flow Summary (total income, total expense for today)

### Rationale
- Allows the agent to resolve ambiguous names ("tiền mặt", "techcom", "momo") accurately to concrete database IDs.
- Enables instant answers to queries like "Ví tiền mặt còn bao nhiêu?" without needing complex SQL execution tools on mobile.
- Enforces safety: The LLM cannot invent non-existent wallet IDs or category IDs.

---

## 5. UI/UX Paradigm: Simo AI Assistant Chat Screen / Modal

### Decision
Create a dedicated `AiAssistantScreen` (or expandable Sheet) featuring:
- **Full Chat Stream**: User messages (right-aligned) and Assistant messages (left-aligned).
- **Embedded Action Cards**: When an action is executed, a clean card is displayed under the assistant's message showing badge (Income/Expense/Transfer/Loan/Goal), amount, and affected entities.
- **Dual Input Bar**: Text input field with send button + Microphone recording button with animated recording status.
- **Quick Action Chips**: Suggestion chips on empty state ("Ăn sáng 35k", "Hôm nay tiêu gì?", "Chuyển tiền ví", "Ví MoMo còn bao nhiêu?").
- **Clear Context Action**: Option to reset conversation history.
