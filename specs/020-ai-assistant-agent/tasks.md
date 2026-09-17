# Tasks: Multimodal Conversational AI Financial Assistant & Agent

**Feature**: `020-ai-assistant-agent`  
**Input**: Design artifacts from `specs/020-ai-assistant-agent/` (`plan.md`, `spec.md`, `research.md`, `data-model.md`, `contracts/`)

---

## Phase 1: Setup (Configuration & Dependencies)

**Purpose**: Configure OpenAI environment variables and ensure compatibility across modules.

- [X] T001 Update environment variable documentation and defaults in `.env.example` to include `AI_BASE_URL`, `AI_API_KEY`, `AI_MODEL` (`gpt-5-nano`), `WHISPER_BASE_URL`, and `WHISPER_MODEL` (`whisper-1`)

---

## Phase 2: Foundational (Core AI Engine & Base Data Models)

**Purpose**: Establish domain models and configure OpenAI services used by all user stories.

**⚠️ CRITICAL**: Must complete before implementing user stories.

- [X] T002 [P] Create AI chat domain models and action payloads in `apps/mobile/lib/models/ai_message.dart` per `data-model.md`
- [X] T003 [P] Update speech transcription service to use OpenAI Whisper endpoint (`https://api.openai.com/v1/audio/transcriptions`) and model `whisper-1` in `apps/mobile/lib/services/speech/whisper_speech_service.dart`
- [X] T004 Modernize AI transaction service in `apps/mobile/lib/services/ai_transaction_service.dart` to default to OpenAI API, use model `gpt-5-nano`, and enforce the dual-output JSON protocol (`contracts/ai-agent-protocol.json`)
- [X] T005 Update AI unit test suite in `apps/mobile/test/ai_engine_test.dart` to validate `gpt-5-nano` structured output and entity parsing

**Checkpoint**: Core OpenAI engine and data models ready and verified.

---

## Phase 3: User Story 1 & 2 - Dual Modality Conversational Assistant & Action Execution (Priority: P1) 🎯 MVP

**Goal**: Users can chat via text or voice dictation in a ChatGPT-style conversation window, and the agent executes financial actions (transactions, transfers, loans, savings) directly.

**Independent Test**: Open AI Assistant, type "Ăn trưa 40k tiền mặt", verify assistant reply and creation of transaction; tap microphone to dictate "Chuyển 100k từ Techcom sang Momo", verify STT transcription and executed transfer.

- [X] T006 [US1] Implement `AiAssistantState` and `AiAssistantNotifier` in `apps/mobile/lib/providers/ai_assistant_provider.dart` managing message streams, STT dictation, and `AiActionDispatcher` execution
- [X] T007 [P] [US1] Create conversational message bubble widget in `apps/mobile/lib/widgets/ai/ai_message_bubble.dart` supporting user and assistant message styling with loading indicators
- [X] T008 [P] [US2] Create visual Action Confirmation Card in `apps/mobile/lib/widgets/ai/ai_action_card.dart` displaying entity icons, amounts, and badges for executed actions
- [X] T009 [US1] Create full-screen conversational interface in `apps/mobile/lib/screens/ai_assistant_screen.dart` with chat scroll view, dual input bar (text input field, send button, and voice dictation button)
- [X] T010 [US1] Update navigation in `apps/mobile/lib/screens/home_screen.dart` to route the central bottom navigation button to `AiAssistantScreen` instead of legacy modal sheet

**Checkpoint**: At this point, the MVP is fully functional. Users can converse via text or voice and autonomously execute financial actions.

---

## Phase 4: User Story 3 - Financial Inquiry & Context Awareness (Priority: P2)

**Goal**: The assistant provides real-time answers to questions regarding user balances, spending, and budgets using an injected financial snapshot.

**Independent Test**: Send "Hôm nay tao đã tiêu bao nhiêu?" or "Ví MoMo còn bao nhiêu?", verify assistant provides accurate numerical answers calculated from the local database without executing mutations.

- [X] T011 [US3] Implement financial snapshot aggregator in `apps/mobile/lib/providers/ai_assistant_provider.dart` compiling active wallets, categories, loans, saving goals, and today's summary metrics
- [X] T012 [US3] Enhance system prompt and context injection in `apps/mobile/lib/services/ai_transaction_service.dart` to handle financial Q&A and distinguish queries from mutations

**Checkpoint**: The assistant can now both execute mutations and answer analytical financial questions.

---

## Phase 5: User Story 4 & 5 - Multi-turn Conversation, Action Cards & Quick Prompts (Priority: P2/P3)

**Goal**: Users can engage in multi-turn dialogues with contextual continuity, clear chat history, and quick action suggestion chips.

**Independent Test**: Open a clean session, tap the "Ăn sáng 35k" quick prompt chip to instantly populate/execute; follow up with "Thêm 10k nước mía nữa", verify the assistant maintains conversational context.

- [X] T013 [P] [US5] Implement quick suggestion prompt chips widget in `apps/mobile/lib/widgets/ai/ai_quick_prompts.dart`
- [X] T014 [US4] Implement multi-turn conversational history management and session reset ("Clear Chat") action in `apps/mobile/lib/providers/ai_assistant_provider.dart` and `apps/mobile/lib/screens/ai_assistant_screen.dart`
- [X] T015 [US4] Embed interactive action inspection cards within `apps/mobile/lib/widgets/ai/ai_message_bubble.dart` allowing users to view executed transaction details

**Checkpoint**: Complete multi-turn experience with quick prompts and rich visual action cards.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Cleanup, deprecations, static analysis, and end-to-end verification.

- [X] T016 [P] Safely deprecate or redirect legacy `VoiceRecordSheet` in `apps/mobile/lib/widgets/voice_record_sheet.dart` to prevent dead-code confusion
- [X] T017 Run static code analysis (`flutter analyze`) across `apps/mobile` and resolve any linter warnings or type mismatches
- [X] T018 Execute automated tests (`flutter test`) in `apps/mobile` to ensure regression-free codebase
- [X] T019 Perform end-to-end validation against scenarios in `specs/020-ai-assistant-agent/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies
- **Phase 1 (Setup)**: Can start immediately.
- **Phase 2 (Foundational)**: Depends on Phase 1; blocks all User Story phases.
- **Phase 3 (User Story 1 & 2 - MVP)**: Depends on Phase 2; produces workable MVP.
- **Phase 4 (User Story 3)**: Depends on Phase 3.
- **Phase 5 (User Story 4 & 5)**: Depends on Phase 3 and Phase 4.
- **Phase 6 (Polish)**: Depends on all user story phases.

### Parallel Opportunities
- In Phase 2: `T002` (`ai_message.dart`) and `T003` (`whisper_speech_service.dart`) can run in parallel.
- In Phase 3: `T007` (`ai_message_bubble.dart`) and `T008` (`ai_action_card.dart`) can be developed in parallel.
- In Phase 5: `T013` (`ai_quick_prompts.dart`) can be developed in parallel.

---

## Implementation Strategy (MVP First)

1. **Step 1**: Complete Phase 1 & Phase 2 (OpenAI `gpt-5-nano` configuration, Whisper endpoint, `AiMessage` models).
2. **Step 2**: Complete Phase 3 (Riverpod provider, UI Screen, Action Cards, Home routing).
3. **Step 3 (Checkpoint)**: Test MVP end-to-end with text and voice commands.
4. **Step 4**: Complete Phase 4 (Context snapshot Q&A) and Phase 5 (Quick chips & multi-turn history).
5. **Step 5**: Complete Phase 6 (Linter, unit tests, quickstart validation).
