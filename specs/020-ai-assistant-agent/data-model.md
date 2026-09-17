# Data Model: Conversational AI Financial Assistant & Agent

**Feature**: `020-ai-assistant-agent`  
**Date**: 2026-09-17  
**Status**: Draft  

---

## 1. Entities & Value Objects

### 1.1 `AiMessage`
Represents an individual message turn in the AI Assistant chat session.

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `id` | `String` (UUID v4) | Yes | Unique identifier of the message |
| `role` | `AiMessageRole` | Yes | Enum: `user`, `assistant`, `system` |
| `content` | `String` | Yes | Text content of the message (Vietnamese speech/text or AI reply) |
| `timestamp` | `DateTime` | Yes | Timestamp when message was created |
| `status` | `AiMessageStatus` | Yes | Enum: `idle`, `sending`, `thinking`, `executed`, `error` |
| `errorMessage` | `String?` | No | Error details if status is `error` |
| `actions` | `List<AiExecutedAction>` | No | List of actions executed alongside this assistant turn |

### 1.2 `AiExecutedAction`
Represents a structured operation executed by the agent for visualization in the UI.

| Field | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `actionType` | `String` | Yes | `transaction`, `transfer`, `loan_create`, `loan_repay`, `goal_deposit`, `goal_withdraw` |
| `title` | `String` | Yes | Human-readable title (e.g. "Chi tiêu", "Chuyển khoản ví", "Cho vay") |
| `amount` | `double` | Yes | Standardized monetary value (VND) |
| `subtitle` | `String` | Yes | Context detail (e.g. "Ăn uống • Ví Tiền mặt", "Từ Techcom $\to$ MoMo") |
| `date` | `DateTime` | Yes | Transaction or action execution date |
| `isSuccess` | `bool` | Yes | Whether the action was committed to local DB successfully |

### 1.3 `AiFinancialContextSnapshot`
Lightweight snapshot sent to OpenAI LLM to provide real-time domain context.

```json
{
  "current_time": "2026-09-17T20:15:00.000Z",
  "wallets": [
    { "id": "uuid-1", "name": "Tiền mặt", "type": "cash", "balance": 1500000 },
    { "id": "uuid-2", "name": "Techcombank", "type": "bank", "balance": 8200000 }
  ],
  "categories": [
    { "id": "cat-1", "name": "Ăn uống", "type": "expense" },
    { "id": "cat-2", "name": "Lương", "type": "income" }
  ],
  "loan_contacts": [
    { "id": "loan-1", "contactName": "Tuấn", "type": "lent", "remainingAmount": 500000 }
  ],
  "saving_goals": [
    { "id": "goal-1", "name": "Mua iPhone", "currentAmount": 12000000, "targetAmount": 25000000 }
  ],
  "today_summary": {
    "total_expense": 125000,
    "total_income": 0,
    "transaction_count": 3
  }
}
```

---

## 2. State Management (`AiAssistantState`)

Managed via `aiAssistantProvider` (`StateNotifier<AiAssistantState>`):

```dart
class AiAssistantState {
  final List<AiMessage> messages;
  final bool isListening;
  final bool isProcessing;
  final String? recognizedSpeechText;
  final String? currentErrorMessage;

  AiAssistantState({
    this.messages = const [],
    this.isListening = false,
    this.isProcessing = false,
    this.recognizedSpeechText,
    this.currentErrorMessage,
  });
}
```

---

## 3. Lifecycle & Transitions

```
[User Input (Text / Voice)] 
      │
      ▼
[Insert User AiMessage (status: sending)]
      │
      ▼
[Insert Assistant Placeholder (status: thinking)]
      │
      ▼
[OpenAI API (gpt-5-nano) Request with Context Snapshot]
      │
      ├───> On Success:
      │       ├── Parse JSON (responseMessage, actions)
      │       ├── Execute AiActionDispatcher.dispatch(...)
      │       └── Update Assistant Message (status: executed, actions attached)
      │
      └───> On Error:
              └── Update Assistant Message (status: error, error message displayed)
```
