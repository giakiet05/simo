# Feature Specification: Multimodal Conversational AI Financial Assistant & Agent

**Feature Branch**: `020-ai-assistant-agent`

**Created**: 2026-09-17

**Status**: Draft

**Input**: User description: "Upgrade AI capabilities: Switch from Groq to OpenAI API with model gpt-5-nano, and transform current voice-only recognition into an interactive ChatGPT-style conversational AI assistant/agent supporting text and speech input that can execute financial operations and answer questions"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Conversational Financial Assistant with Text & Voice Input (Priority: P1)

As a user managing daily finances, I want to interact with a conversational assistant either by typing text messages or by speaking into the microphone, so that I have the flexibility to log transactions and manage my finances quickly in any environment (e.g., quiet office or on-the-go).

**Why this priority**: Moving from a voice-only popup to a full-fledged ChatGPT-style assistant removes current usability constraints, enabling quiet text interactions, reviewable history, and clear interactive feedback.

**Independent Test**: Can be tested by opening the AI Assistant screen, entering a message via the text input field, verifying immediate AI response in the conversation bubble, then tapping the microphone to dictate a command and verifying accurate speech-to-text transcription and response.

**Acceptance Scenarios**:
1. **Given** the user is on any screen, **When** they trigger the AI Assistant from the navigation bar, **Then** an interactive conversation window opens with chat history, quick action prompts, and an input bar.
2. **Given** the conversation input bar, **When** the user types "Ăn sáng 45k tiền mặt" and sends, **Then** the message appears in the chat stream, and the assistant processes the request without requiring audio input.
3. **Given** the user taps the microphone button, **When** speech is detected and finished, **Then** the transcribed text is displayed and processed seamlessly by the AI assistant.

---

### User Story 2 - Autonomous AI Agent Financial Action Execution (Priority: P1)

As a user giving natural language commands, I want the assistant to autonomously parse my intent and execute the corresponding financial actions (record expense/income, transfer between wallets, log loan/borrow records, or allocate savings goals) without forcing me to navigate multiple screens or forms.

**Why this priority**: The core value proposition of an AI Agent is taking action on behalf of the user directly from natural language, drastically cutting the time and friction required for financial tracking.

**Independent Test**: Can be tested by sending a compound command such as "Vừa đổ xăng 50k ví Tiền mặt và chuyển 500k từ VCB sang Momo", verifying that both the transaction and the wallet transfer are executed in the database, and observing the assistant return a concise confirmation message.

**Acceptance Scenarios**:
1. **Given** an expense command with implicit or explicit wallet details, **When** processed by the assistant, **Then** a new transaction record is committed, relevant wallet balances update, and the assistant confirms the details.
2. **Given** a fund transfer command between two wallets, **When** processed, **Then** the transfer is registered, source and destination balances adjust, and the assistant summarizes the completed transfer.
3. **Given** a debt/loan command (e.g., "Cho Tuấn mượn 200k"), **When** processed, **Then** the loan contact and loan transaction records are updated, and the user receives confirmation.
4. **Given** a saving goal command (e.g., "Tiết kiệm 1 triệu vào quỹ mua xe"), **When** processed, **Then** the saving goal log is added, current accumulated progress increments, and the assistant reports progress.

---

### User Story 3 - Natural Financial Inquiry & Context Awareness (Priority: P2)

As a user checking my financial health, I want to ask questions in plain Vietnamese about my balances, spending habits, and budgets, so that the assistant can provide immediate, contextual summaries without requiring me to inspect raw charts or reports.

**Why this priority**: An intelligent assistant should not only write data, but also read and synthesize existing data, empowering users to make informed financial decisions through dialogue.

**Independent Test**: Can be tested by asking "Hôm nay tôi đã tiêu bao nhiêu tiền?" or "Ví Momo của tôi còn bao nhiêu?", verifying that the assistant calculates the figures from current database context and provides an accurate, readable reply.

**Acceptance Scenarios**:
1. **Given** existing transactions recorded for today, **When** the user asks about today's spending, **Then** the assistant calculates the daily total and summarizes top expense categories.
2. **Given** active user wallets, **When** the user asks for their wallet balances, **Then** the assistant returns the exact balance breakdown per wallet.
3. **Given** a conversational question unrelated to mutation, **When** processed, **Then** no unintended database mutations are executed.

---

### User Story 4 - Multi-turn Conversation & Visual Action Confirmation Cards (Priority: P2)

As a user interacting over multiple turns, I want the assistant to remember recent conversational context and display visual "Action Cards" alongside text replies, so that I can clearly audit and inspect what actions were executed.

**Why this priority**: Pure text confirmations can be ambiguous; visual summary cards provide immediate transparency, building trust between the user and the autonomous agent.

**Independent Test**: Can be tested by issuing a transaction command, observing the AI response containing an embedded structured card with amount, category icon, and wallet, and tapping the card to inspect or jump to the transaction detail.

**Acceptance Scenarios**:
1. **Given** an executed action, **When** the assistant responds, **Then** a visual card is rendered beneath the message bubble showing entity details (amount, category, wallet badge, status).
2. **Given** an ongoing conversation, **When** the user follows up with contextual references (e.g., "Ghi thêm 20k nữa"), **Then** the assistant correctly understands the contextual continuity.
3. **Given** a completed session, **When** the user wants a clean slate, **Then** a "Clear Chat" option is available to reset conversational context.

---

### User Story 5 - Quick Suggestion Chips & Guided Prompts (Priority: P3)

As a user opening the assistant for the first time or wanting rapid shortcuts, I want to see helpful suggestion chips (e.g., "Ghi chi tiêu hôm nay", "Chuyển tiền ví", "Tình hình tài chính"), so that I can trigger common flows with a single tap.

**Why this priority**: Reduces cognitive load, demonstrates system capabilities, and speeds up frequent interactions for new and returning users.

**Independent Test**: Can be tested by opening a blank assistant session, tapping a suggestion chip, and confirming that the prompt is automatically sent or populated into the input bar.

**Acceptance Scenarios**:
1. **Given** an empty chat session, **When** opened, **Then** suggestion chips for common queries and actions are displayed.
2. **Given** a tapped suggestion chip, **When** selected, **Then** it immediately executes the corresponding action or prefills the input bar.

---

### Edge Cases

- **Ambiguous or Incomplete Input**: When the user provides incomplete info (e.g., "Vừa tiêu tiền" without amount), the assistant politely asks for clarification instead of creating an empty or zero-value transaction.
- **Unsupported Action or Intent**: When the user asks general or out-of-scope questions (e.g., "Thời tiết hôm nay thế nào?"), the assistant politely guides the user back to personal finance tracking.
- **Network Outage / API Failure**: If the network disconnects or the AI provider returns a timeout/rate-limit error, the assistant displays an inline error bubble with a "Retry" button rather than crashing or hanging silently.
- **Colloquial Vietnamese Currency Parsing**: The system accurately parses colloquial terms ("k", "cành", "lít", "củ", "chục", "vạn") and handles potential transcription typos from speech.
- **Concurrent Actions in Single Utterance**: When the user utters multiple actions in one sentence (e.g., "Ăn trưa 50k và cho Nam mượn 100k"), the assistant atomically parses and executes both actions, presenting individual confirmation cards.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a dedicated conversational AI Assistant interface accessible from the primary navigation bar.
- **FR-002**: System MUST support dual-input modalities: text input via standard software keyboard and voice input via high-accuracy speech-to-text.
- **FR-003**: System MUST utilize a high-throughput, low-latency advanced language model (`gpt-5-nano` via OpenAI API standard) for natural language reasoning, action extraction, and response generation.
- **FR-004**: System MUST autonomously execute transactions (income/expense), wallet transfers, loans/debts, and saving goal contributions without requiring manual form navigation.
- **FR-005**: System MUST render structured visual Action Cards for every executed mutation, detailing amounts, categories, wallets, and execution status.
- **FR-006**: System MUST supply user financial context (wallets, active budgets, categories, recent transactions) to the assistant model to enable accurate financial queries and entity resolution.
- **FR-007**: System MUST maintain multi-turn conversational history within the active session, allowing users to reference previous statements or clear session history.
- **FR-008**: System MUST display real-time status indicators (listening, transcribing, thinking, executing) to ensure clear user feedback during processing.
- **FR-009**: System MUST support graceful error handling, reporting clear explanations when a request cannot be fulfilled and offering retry mechanisms.

### Key Entities

- **AI Chat Message**: Represents an individual dialogue turn (sender: user or assistant, text content, timestamp, attached action payloads, and execution state).
- **AI Action Intent**: Encapsulates an extracted business operation (action type, amount, source/destination wallets, categories, contact IDs, goal IDs, notes, and dates).
- **Financial Context Snapshot**: A lightweight structured representation of the user's available financial metadata (categories, wallets, loans, goals) injected as conversational context.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: End-to-end response time (from user message submission to assistant reply and action execution) is under 2.5 seconds on standard mobile network connections.
- **SC-002**: Financial entity and intent parsing accuracy achieves 95%+ across standard Vietnamese personal finance utterances and slang.
- **SC-003**: 100% of executed actions generate clear, human-verifiable visual confirmations in the chat thread.
- **SC-004**: Zero silent failures: any parsing ambiguity or execution error produces an actionable, understandable explanation to the user.
- **SC-005**: Full modality parity: users can achieve 100% of financial logging capabilities using voice or text interchangeably.

---

## Assumptions

- Users have internet access required to connect to the cloud AI service.
- The OpenAI API key is supplied via application environment configuration (`.env`).
- Local microphone permissions will continue to be requested and managed for voice dictation.
- The existing SQLite repositories and Riverpod state notifiers will be reused for executing data mutations.
