# Data Model: ReAct AI Agent Architecture with Full CRUD & Multi-turn Clarification

**Feature**: `022-react-agent-full-crud`

## 1. Agent Runtime State Model

### `AiAssistantState`
State entity representing the live conversational session and active agent execution.

| Field | Type | Description |
| :--- | :--- | :--- |
| `messages` | `List<AiMessage>` | Full chronological dialogue turns |
| `isListening` | `bool` | Audio recording state |
| `isProcessing` | `bool` | ReAct reasoning / Tool execution in progress |
| `recognizedSpeechText` | `String` | Live STT transcript |
| `errorMessage` | `String?` | Error display banner |
| `horizonIndex` | `int?` | Horizon boundary index separating active turns from pruned memory |
| `pendingIntent` | `PendingIntent?` | Active incomplete intent awaiting user clarification |

---

### `PendingIntent` (Slot-Filling Entity)
Captures an action that was halted due to missing mandatory parameters.

| Field | Type | Description |
| :--- | :--- | :--- |
| `actionType` | `String` | Tool name (e.g. `loan_create`, `transfer`, `goal_deposit`) |
| `extractedSlots` | `Map<String, dynamic>` | Key-value pairs already extracted (e.g. `amount: 200000`, `loanType: "lent"`) |
| `missingFields` | `List<String>` | Required fields needed from user (e.g. `["contactName"]`) |
| `clarificationQuestion` | `String` | Question asked to the user |
| `createdAt` | `DateTime` | Timestamp for session TTL expiration |

---

### `AiMessage` Model (Enhanced for ReAct)
Represents a message turn supporting text, tool invocations, tool observations, and generative UI payloads.

| Field | Type | Description |
| :--- | :--- | :--- |
| `id` | `String` | UUID |
| `role` | `String` | `'user'`, `'assistant'`, `'system'`, `'tool'` |
| `content` | `String?` | Plain text content |
| `toolCalls` | `List<AiToolCall>?` | Tool calls requested by assistant |
| `toolCallId` | `String?` | Identifier linking `tool` message to `tool_call` |
| `actions` | `List<AiExecutedAction>?` | Human-readable summary of executed mutations |
| `viewPayload` | `AiViewPayload?` | Generative UI payload (TransactionList, WalletCard, DebtCard, GoalCard) |
| `timestamp` | `DateTime` | Message timestamp |

---

## 2. Tool Execution Models

### `AgentToolResult` (Observation Feedback)
Standardized output returned by every tool to feed back into the ReAct reasoning loop.

```dart
class AgentToolResult {
  final bool isSuccess;
  final Map<String, dynamic> data;
  final String? errorMessage;
  final dynamic uiPayload; // AiViewPayload if read query
}
```

---

## 3. Entity CRUD Operation Matrix

| Entity | Fields Modifiable via Agent | Validation / Pre-condition Rules |
| :--- | :--- | :--- |
| **Transaction** | `amount`, `categoryId`, `walletId`, `date`, `note`, `type` | `amount > 0`, `walletId` must exist, adjust old and new wallet balance |
| **Wallet** | `name`, `type`, `icon`, `color`, `isDefault`, `currentBalance` | Name non-empty, only one default wallet |
| **Category** | `name`, `type`, `icon`, `color`, `budgetLimit` | Non-empty name, system categories (`sys_*`) cannot be edited or deleted |
| **Budget** | `amount`, `categoryId`, `month` (YYYY-MM) | `amount >= 0` (0 = clear budget) |
| **LoanContact** | `contactName`, `totalAmount`, `remainingAmount`, `dueDate`, `note` | `remainingAmount <= totalAmount`, `dueDate >= today` |
| **SavingGoal** | `name`, `targetAmount`, `targetDate`, `status` | `targetAmount > 0` |
| **Recurring** | `name`, `amount`, `frequency`, `dayOfMonth`, `categoryId`, `walletId`, `isActive` | `amount > 0`, `1 <= dayOfMonth <= 31` |
