import 'package:uuid/uuid.dart';

/// Role of the message participant in the AI conversation.
enum AiMessageRole {
  user,
  assistant,
  system,
}

/// Execution and delivery status of an AI message.
enum AiMessageStatus {
  idle,
  sending,
  thinking,
  executed,
  error,
}

/// Represents an individual structured action executed by the AI agent.
class AiExecutedAction {
  /// The specific operation type performed (e.g., transaction, transfer, loan_create).
  final String actionType;

  /// High-level readable title for presentation (e.g. "Chi tieu", "Chuyen khoan").
  final String title;

  /// Standardized numerical amount in local currency (VND).
  final double amount;

  /// Descriptive subtitle with entity details (e.g., wallet names, category).
  final String subtitle;

  /// Timestamp associated with the action.
  final DateTime date;

  /// Indicates whether the local database persistence succeeded.
  final bool isSuccess;

  /// Raw action payload received from the model parser.
  final Map<String, dynamic>? rawAction;

  const AiExecutedAction({
    required this.actionType,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.date,
    this.isSuccess = true,
    this.rawAction,
  });

  /// Factory constructor to convert a raw parsed action map to an executed action representation.
  factory AiExecutedAction.fromRawAction({
    required Map<String, dynamic> rawAction,
    required String title,
    required String subtitle,
    bool isSuccess = true,
  }) {
    final double amount = (rawAction['amount'] as num?)?.toDouble() ?? 0.0;
    final dateStr = rawAction['date'] as String?;
    final DateTime parsedDate = dateStr != null
        ? (DateTime.tryParse(dateStr) ?? DateTime.now())
        : DateTime.now();

    return AiExecutedAction(
      actionType: rawAction['actionType'] as String? ?? 'transaction',
      title: title,
      amount: amount,
      subtitle: subtitle,
      date: parsedDate,
      isSuccess: isSuccess,
      rawAction: rawAction,
    );
  }
}

/// Represents an individual chat message in the conversational AI Assistant stream.
class AiMessage {
  /// Unique identifier of the message.
  final String id;

  /// Participant role for this turn (user or assistant).
  final AiMessageRole role;

  /// Text content of the dialogue turn.
  final String content;

  /// Creation timestamp.
  final DateTime timestamp;

  /// Current processing or delivery state.
  final AiMessageStatus status;

  /// Detailed human-readable error description when status is error.
  final String? errorMessage;

  /// List of structured operations performed alongside this assistant turn.
  final List<AiExecutedAction> actions;

  const AiMessage({
    required this.id,
    required this.role,
    required this.content,
    required this.timestamp,
    this.status = AiMessageStatus.idle,
    this.errorMessage,
    this.actions = const [],
  });

  /// Convenience constructor to instantiate a new user message.
  factory AiMessage.user(String content) {
    return AiMessage(
      id: const Uuid().v4(),
      role: AiMessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      status: AiMessageStatus.idle,
    );
  }

  /// Convenience constructor to instantiate an assistant placeholder message while processing.
  factory AiMessage.assistantThinking() {
    return AiMessage(
      id: const Uuid().v4(),
      role: AiMessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      status: AiMessageStatus.thinking,
    );
  }

  /// Convenience constructor to instantiate a completed assistant message.
  factory AiMessage.assistant({
    required String content,
    List<AiExecutedAction> actions = const [],
  }) {
    return AiMessage(
      id: const Uuid().v4(),
      role: AiMessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      status: AiMessageStatus.executed,
      actions: actions,
    );
  }

  /// Convenience constructor to instantiate an error assistant message.
  factory AiMessage.error({
    required String errorMessage,
    String content = '',
  }) {
    return AiMessage(
      id: const Uuid().v4(),
      role: AiMessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      status: AiMessageStatus.error,
      errorMessage: errorMessage,
    );
  }

  /// Creates a copy of this message with updated fields.
  AiMessage copyWith({
    String? id,
    AiMessageRole? role,
    String? content,
    DateTime? timestamp,
    AiMessageStatus? status,
    String? errorMessage,
    List<AiExecutedAction>? actions,
  }) {
    return AiMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      actions: actions ?? this.actions,
    );
  }
}
