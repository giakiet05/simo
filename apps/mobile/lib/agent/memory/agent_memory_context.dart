import 'package:dart_openai/dart_openai.dart';
import '../../models/ai_message.dart';

/// Manages conversational memory bounds, sliding window FIFO context, and memory horizon indexing.
class AgentMemoryContext {
  /// Maximum number of recent dialogue turns to include in the LLM working context.
  static const int maxWorkingTurns = 10;

  /// Extracts the bounded sliding window of dialogue turns formatted for LLM payload.
  /// Ignores thinking or intermediate status messages.
  static List<Map<String, String>> extractWorkingTurns(List<AiMessage> messages) {
    final turns = <Map<String, String>>[];

    for (final msg in messages) {
      if (msg.status == AiMessageStatus.thinking) continue;
      if (msg.role == AiMessageRole.user) {
        turns.add({'role': 'user', 'content': msg.content});
      } else if (msg.role == AiMessageRole.assistant && msg.content.isNotEmpty) {
        turns.add({'role': 'assistant', 'content': msg.content});
      }
    }

    if (turns.length > maxWorkingTurns) {
      return turns.sublist(turns.length - maxWorkingTurns);
    }
    return turns;
  }

  /// Extracts dialogue turns as [OpenAIChatCompletionChoiceMessageModel] for direct OpenAI Chat API invocation.
  static List<OpenAIChatCompletionChoiceMessageModel> extractOpenAiWorkingMessages(
    List<AiMessage> messages,
  ) {
    final result = <OpenAIChatCompletionChoiceMessageModel>[];
    final workingTurns = extractWorkingTurns(messages);

    for (final turn in workingTurns) {
      final role = turn['role'] == 'user'
          ? OpenAIChatMessageRole.user
          : OpenAIChatMessageRole.assistant;
      final content = turn['content'] ?? '';
      if (content.isNotEmpty) {
        result.add(
          OpenAIChatCompletionChoiceMessageModel(
            role: role,
            content: [
              OpenAIChatCompletionChoiceMessageContentItemModel.text(content),
            ],
          ),
        );
      }
    }

    return result;
  }

  /// Calculates the 0-based index in the full message list where the active 10-turn memory horizon begins.
  /// Returns null if total valid messages is <= maxWorkingTurns (meaning all messages are in memory).
  static int? calculateHorizonIndex(List<AiMessage> messages) {
    final validIndices = <int>[];
    for (int i = 0; i < messages.length; i++) {
      if (messages[i].status != AiMessageStatus.thinking &&
          (messages[i].role == AiMessageRole.user || messages[i].role == AiMessageRole.assistant)) {
        validIndices.add(i);
      }
    }

    if (validIndices.length <= maxWorkingTurns) {
      return null;
    }

    // The boundary is the index of the message at (validIndices.length - maxWorkingTurns)
    final boundaryTarget = validIndices.length - maxWorkingTurns;
    return validIndices[boundaryTarget];
  }
}
