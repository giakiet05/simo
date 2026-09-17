import 'package:flutter/foundation.dart';
import 'agent_tool.dart';

/// Central registry for managing, introspecting, and dispatching all Simo Agent tools.
class ToolRegistry {
  final Map<String, SimoAgentTool> _tools = {};

  /// Registers a new tool into the registry.
  void register(SimoAgentTool tool) {
    _tools[tool.name] = tool;
  }

  /// Retrieves a registered tool by its name.
  SimoAgentTool? getTool(String name) => _tools[name];

  /// Checks if a tool with given name is registered.
  bool hasTool(String name) => _tools.containsKey(name);

  /// Returns all registered tools.
  List<SimoAgentTool> getAllTools() => _tools.values.toList();

  /// Dispatches execution to a registered tool by name with raw parameter map.
  Future<dynamic> dispatch(
    String toolName,
    Map<String, dynamic> rawInput,
    AgentExecutionContext context,
  ) async {
    final tool = _tools[toolName];
    if (tool == null) {
      debugPrint('ToolRegistry: No tool registered for "$toolName"');
      return null;
    }

    try {
      debugPrint('ToolRegistry: Executing tool "$toolName" with input: $rawInput');
      return await tool.execute(rawInput, context);
    } catch (e, stack) {
      debugPrint('ToolRegistry: Error executing tool "$toolName": $e\n$stack');
      rethrow;
    }
  }
}
