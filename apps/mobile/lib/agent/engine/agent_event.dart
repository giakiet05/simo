import '../../models/ai_message.dart';

/// Standardized output returned by every tool to feed back into the ReAct reasoning loop.
class AgentToolResult {
  /// Indicates whether the tool execution succeeded.
  final bool isSuccess;

  /// Structured diagnostic data or entity identifiers.
  final Map<String, dynamic> data;

  /// Human- or LLM-readable diagnostic error message when execution fails.
  final String? errorMessage;

  /// Optional rich visual data payload (e.g. [AiViewPayload]) for UI rendering.
  final dynamic uiPayload;

  const AgentToolResult({
    required this.isSuccess,
    this.data = const {},
    this.errorMessage,
    this.uiPayload,
  });

  /// Factory constructor for successful tool execution.
  factory AgentToolResult.success([
    Map<String, dynamic> data = const {},
    dynamic uiPayload,
  ]) =>
      AgentToolResult(isSuccess: true, data: data, uiPayload: uiPayload);

  /// Factory constructor for failed tool execution with diagnostic error message.
  factory AgentToolResult.error(
    String message, [
    Map<String, dynamic> data = const {},
  ]) =>
      AgentToolResult(isSuccess: false, errorMessage: message, data: data);

  /// Converts the tool result to a JSON map suitable for observation feedback.
  Map<String, dynamic> toJson() => {
        'isSuccess': isSuccess,
        'data': data,
        if (errorMessage != null) 'errorMessage': errorMessage,
      };

  @override
  String toString() =>
      'AgentToolResult(isSuccess: $isSuccess, data: $data, errorMessage: $errorMessage)';
}

/// Base class for all lifecycle events emitted during ReAct agent execution.
sealed class AgentEvent {
  const AgentEvent();
}

/// Emitted at the start of a ReAct execution round.
class AgentRoundStartedEvent extends AgentEvent {
  /// Current round index (1-indexed).
  final int round;

  /// Maximum allowed rounds for this cycle.
  final int maxRounds;

  const AgentRoundStartedEvent({
    required this.round,
    required this.maxRounds,
  });
}

/// Emitted when sending conversational context to the LLM.
class AgentModelCallEvent extends AgentEvent {
  /// Round number in which the model call is initiated.
  final int round;

  /// Brief description or token estimate for debugging.
  final String modelId;

  const AgentModelCallEvent({
    required this.round,
    required this.modelId,
  });
}

/// Emitted before executing an individual tool call.
class AgentToolExecutionEvent extends AgentEvent {
  /// The tool name requested by the LLM.
  final String toolName;

  /// Arguments provided by the LLM.
  final Map<String, dynamic> arguments;

  /// Unique tool call ID from OpenAI Tool Calling protocol.
  final String? toolCallId;

  const AgentToolExecutionEvent({
    required this.toolName,
    required this.arguments,
    this.toolCallId,
  });
}

/// Emitted after a tool finishes execution, providing observation feedback.
class AgentToolResultEvent extends AgentEvent {
  /// Name of the tool that executed.
  final String toolName;

  /// Execution result containing status, output data, or error message.
  final AgentToolResult result;

  /// Unique tool call ID.
  final String? toolCallId;

  const AgentToolResultEvent({
    required this.toolName,
    required this.result,
    this.toolCallId,
  });
}

/// Emitted when the ReAct loop reaches a final natural language answer.
class AgentFinalAnswerEvent extends AgentEvent {
  /// The final text response or clarification question.
  final String content;

  /// List of structured mutations executed across all rounds.
  final List<AiExecutedAction> actions;

  /// Optional visual card payload attached by query tools.
  final AiViewPayload? viewPayload;

  const AgentFinalAnswerEvent({
    required this.content,
    this.actions = const [],
    this.viewPayload,
  });
}

/// Emitted when an unrecoverable failure occurs during ReAct execution.
class AgentErrorEvent extends AgentEvent {
  /// The error description.
  final String errorMessage;

  const AgentErrorEvent({
    required this.errorMessage,
  });
}
