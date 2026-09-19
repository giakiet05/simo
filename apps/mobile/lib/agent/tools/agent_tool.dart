import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Context provided to tools during execution.
/// Contains references to state providers, cached entities, and optional navigation callbacks.
class AgentExecutionContext {
  /// Riverpod Ref to interact with app state providers.
  final Ref ref;

  /// Optional navigation callback for UI transitions.
  final Future<void> Function(String route, {Map<String, dynamic>? arguments})? onNavigate;

  const AgentExecutionContext({
    required this.ref,
    this.onNavigate,
  });
}

/// Abstract interface for all executable capabilities available to the Simo AI Agent.
abstract class SimoAgentTool<TInput, TOutput> {
  /// Unique identifier of the tool matching LLM schema protocol (e.g., 'budget_set', 'query_transactions').
  String get name;

  /// Human- and LLM-readable description of what the tool accomplishes.
  String get description;

  /// JSON Schema parameters accepted by the tool.
  Map<String, dynamic> get parametersSchema;

  /// Indicates whether the tool performs a destructive operation (e.g. deletion, bulk modifications).
  bool get isDestructive => false;

  /// Executes the tool logic with the given input and execution context.
  Future<TOutput> execute(TInput input, AgentExecutionContext context);
}

/// Utility for parsing dates from AI agent inputs.
/// Attaches current time components if the LLM supplies a date-only string or midnight timestamp (00:00:00).
class AgentDateHelper {
  /// Parses an ISO date string or date-only string into a DateTime.
  ///
  /// @param dateStr Raw input string from AI or user.
  /// @param referenceNow Optional reference time (defaults to DateTime.now()).
  /// @returns DateTime with realistic hour, minute, and second.
  static DateTime parseDate(String? dateStr, [DateTime? referenceNow]) {
    final now = referenceNow ?? DateTime.now();
    if (dateStr == null || dateStr.trim().isEmpty) {
      return now;
    }
    final parsed = DateTime.tryParse(dateStr.trim());
    if (parsed == null) {
      return now;
    }
    // If the parsed date has no explicit time component (00:00:00.000), preserve current time of day
    if (parsed.hour == 0 && parsed.minute == 0 && parsed.second == 0 && parsed.millisecond == 0) {
      return DateTime(
        parsed.year,
        parsed.month,
        parsed.day,
        now.hour,
        now.minute,
        now.second,
      );
    }
    return parsed;
  }
}
