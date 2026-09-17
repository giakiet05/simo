import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'system_prompt_builder.dart';
import 'protocol_parser.dart';

/// The central Orchestrator / Brain of the Simo Autonomous AI Agent.
class AgentBrain {
  AgentBrain() {
    _ensureConfigured();
  }

  String _getApiKey() {
    return dotenv.env['AI_API_KEY'] ??
        dotenv.env['OPENAI_API_KEY'] ??
        '';
  }

  void _ensureConfigured() {
    String baseUrl = dotenv.env['AI_BASE_URL'] ??
        dotenv.env['OPENAI_BASE_URL'] ??
        'https://api.openai.com';
    while (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    if (baseUrl.endsWith('/v1')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 3);
    }
    OpenAI.baseUrl = baseUrl;
    OpenAI.requestsTimeOut = const Duration(seconds: 45);
    final key = _getApiKey();
    if (key.isNotEmpty) {
      OpenAI.apiKey = key;
    }
  }

  /// Processes user input with live financial snapshot and bounded conversational history.
  Future<AgentBrainResult> process({
    required String userInput,
    required String financialSnapshot,
    required List<Map<String, String>> workingHistory,
  }) async {
    _ensureConfigured();

    final apiKey = _getApiKey();
    if (apiKey.isEmpty) {
      debugPrint('AgentBrain: No API key found in .env (checked AI_API_KEY, OPENAI_API_KEY)');
      return const AgentBrainResult(
        isSuccess: false,
        responseMessage: 'Bạn chưa cấu hình OpenAI API Key trong file .env. Vui lòng thêm AI_API_KEY=sk-... vào file .env nhé!',
        thought: 'Missing API Key',
      );
    }

    final modelId = dotenv.env['AI_MODEL'] ?? 'gpt-4o-mini';
    final systemPrompt = SystemPromptBuilder.build(financialSnapshot: financialSnapshot);

    final messagesList = <OpenAIChatCompletionChoiceMessageModel>[
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt)],
      ),
    ];

    // Append bounded working context turns
    for (final turn in workingHistory) {
      final role = turn['role'] == 'user'
          ? OpenAIChatMessageRole.user
          : OpenAIChatMessageRole.assistant;
      final content = turn['content'] ?? '';
      if (content.isNotEmpty) {
        messagesList.add(
          OpenAIChatCompletionChoiceMessageModel(
            role: role,
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(content)],
          ),
        );
      }
    }

    // Append current user turn
    messagesList.add(
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.user,
        content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(userInput)],
      ),
    );

    try {
      final chatCompletion = await OpenAI.instance.chat.create(
        model: modelId,
        messages: messagesList,
        responseFormat: const {"type": "json_object"},
      );

      final contentItems = chatCompletion.choices.first.message.content;
      String rawText = '';
      if (contentItems != null && contentItems.isNotEmpty) {
        rawText = contentItems.map((c) => c.text ?? '').join();
      }

      return ProtocolParser.parse(rawText);
    } on TimeoutException catch (e) {
      debugPrint('AgentBrain: TimeoutException $e');
      return const AgentBrainResult(
        isSuccess: false,
        responseMessage: 'Kết nối tới OpenAI bị quá thời gian chờ (Timeout). Bạn vui lòng thử lại nhé!',
        thought: 'Request Timeout',
      );
    } catch (e) {
      debugPrint('AgentBrain error: $e');
      final errStr = e.toString();
      if (errStr.contains('401') || errStr.contains('API key')) {
        return const AgentBrainResult(
          isSuccess: false,
          responseMessage: 'API Key không hợp lệ hoặc tài khoản hết hạn (Lỗi 401). Vui lòng kiểm tra lại file .env nhé!',
          thought: 'Invalid API Key (401)',
        );
      }
      return AgentBrainResult(
        isSuccess: false,
        responseMessage: 'Có lỗi xảy ra khi kết nối với AI: $errStr',
        thought: 'Execution Exception',
      );
    }
  }
}
