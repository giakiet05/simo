# Implementation Plan: Multimodal Conversational AI Financial Assistant & Agent

**Branch**: `020-ai-assistant-agent` | **Date**: 2026-09-17 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/020-ai-assistant-agent/spec.md`

## Summary

Upgrade Simo's AI capabilities by migrating from Groq to standard **OpenAI API** using the **`gpt-5-nano`** model, and transforming the existing 350px voice-only sheet into a full-featured, ChatGPT-style **Conversational AI Financial Assistant & Agent**. The assistant supports multimodal input (typing and voice dictation via Whisper), executes financial mutations autonomously (transactions, transfers, debts, goals), answers natural language financial inquiries with real-time financial context, and displays interactive Action Confirmation Cards.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter SDK  
**Primary Dependencies**: `flutter_riverpod` (v2.6.1), `dart_openai` (v6.1.1), `record` (v7.1.1), `flutter_dotenv` (v5.1.0), `uuid` (v4.5.1)  
**Storage**: SQLite local database (`sqflite`), existing repository layer (`transaction_repository`, `wallet_repository`, etc.)  
**Testing**: `flutter test` (`test/ai_engine_test.dart`)  
**Target Platform**: Android, iOS (Flutter Mobile)  
**Project Type**: Mobile App / Client-side AI Agent  
**Performance Goals**: End-to-end response & action execution under 2.5s; STT transcription under 1.5s  
**Constraints**: Zero secrets in client source code; graceful offline/error degradation; strict adherence to Clean Architecture / DRY / KISS  
**Scale/Scope**: Mobile app feature module (Services, Providers, Models, UI Widgets, Screen)  

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

| Gate / Principle | Status | Evaluation |
| :--- | :--- | :--- |
| **I. Clean Architecture & Layering** | **PASS** | Logic cleanly separated: Service (`ai_transaction_service`), Provider (`ai_assistant_provider`), UI (`ai_assistant_screen`). |
| **II. Zero Secret Leaks** | **PASS** | API keys loaded strictly via `flutter_dotenv` (`AI_API_KEY`), never hardcoded. |
| **III. Test-First & Verifiability** | **PASS** | Automated test suite in `test/ai_engine_test.dart` and `flutter analyze` lint checks. |
| **IV. English-Only Codebase** | **PASS** | 100% English variable, method, class names, comments, and commit messages. UI display strings localized for Vietnamese users. |
| **V. No Placeholders / Complete Code** | **PASS** | Production-ready implementation with proper error handling and fallback states. |

## Project Structure

### Documentation (this feature)

```text
specs/020-ai-assistant-agent/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output: decisions on gpt-5-nano, dual-output protocol, Whisper
├── data-model.md        # Phase 1 output: AiMessage, AiExecutedAction, AiAssistantState
├── quickstart.md        # Phase 1 output: end-to-end validation scenarios
├── contracts/           # Phase 1 output: JSON schema for gpt-5-nano output
│   └── ai-agent-protocol.json
└── checklists/
    └── requirements.md  # Quality validation checklist
```

### Source Code (Mobile App)

```text
apps/mobile/lib/
├── models/
│   └── ai_message.dart                 # [NEW] Chat message entity & executed action payloads
├── services/
│   ├── ai_transaction_service.dart     # [MODIFY] OpenAI API default, gpt-5-nano, context prompt
│   ├── ai_action_dispatcher.dart       # [MAINTAIN] Existing execution dispatcher
│   └── speech/
│       └── whisper_speech_service.dart # [MODIFY] OpenAI Whisper endpoint & whisper-1 model
├── providers/
│   └── ai_assistant_provider.dart      # [NEW] Riverpod state notifier for chat & agent flow
├── widgets/
│   ├── ai/
│   │   ├── ai_message_bubble.dart      # [NEW] User & Assistant message bubbles
│   │   ├── ai_action_card.dart         # [NEW] Visual confirmation card for executed actions
│   │   └── ai_quick_prompts.dart       # [NEW] Quick suggestion chips
│   └── voice_record_sheet.dart         # [DEPRECATE / REDIRECT]
└── screens/
    ├── ai_assistant_screen.dart        # [NEW] Full conversational assistant screen
    └── home_screen.dart                # [MODIFY] Central bottom nav button routes to AI Assistant
```

## Structure Decision

The architecture extends the existing Flutter Riverpod structure in `apps/mobile/lib/`. The AI assistant is structured into:
1. **Domain & Models**: `ai_message.dart` defines immutable message and action payloads.
2. **Infrastructure / Services**: `ai_transaction_service.dart` handles API communication with OpenAI using `dart_openai`.
3. **Application State**: `ai_assistant_provider.dart` coordinates between the UI, OpenAI API, and `AiActionDispatcher`.
4. **Presentation**: `ai_assistant_screen.dart` and specialized widgets under `widgets/ai/` present the ChatGPT-like conversational interface.

## Complexity Tracking

*No constitutional violations identified. Standard Flutter/Riverpod pattern applied.*
