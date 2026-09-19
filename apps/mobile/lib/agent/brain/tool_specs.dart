import 'package:dart_openai/dart_openai.dart';
import '../tools/agent_tool.dart';
import '../tools/tool_registry.dart';

/// Utility to build OpenAI Tool Calling specifications from registered SimoAgentTools.
class OpenAiToolSpecs {
  /// Converts a single [SimoAgentTool] into an [OpenAIToolModel].
  static OpenAIToolModel fromTool(SimoAgentTool tool) {
    return OpenAIToolModel(
      type: 'function',
      function: OpenAIFunctionModel(
        name: tool.name,
        description: tool.description,
        parametersSchema: tool.parametersSchema,
      ),
    );
  }

  /// Converts all tools from a [ToolRegistry] into a list of [OpenAIToolModel] instances.
  static List<OpenAIToolModel> fromRegistry(ToolRegistry registry) {
    return registry.getAllTools().map(fromTool).toList();
  }
}
