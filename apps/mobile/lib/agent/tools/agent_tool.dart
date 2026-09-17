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
