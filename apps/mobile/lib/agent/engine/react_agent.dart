import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../models/ai_message.dart';
import '../brain/system_prompt_builder.dart';
import '../brain/tool_specs.dart';
import '../tools/agent_tool.dart';
import '../tools/tool_registry.dart';
import 'agent_event.dart';

/// The pure Dart ReAct (Reasoning + Acting + Observation Feedback) Execution Engine.
/// Orchestrates multi-round tool calling, observation ingestion, and final answer synthesis.
class ReActAgent {
  final ToolRegistry toolRegistry;
  final AgentExecutionContext executionContext;

  ReActAgent({
    required this.toolRegistry,
    required this.executionContext,
  });

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
    final key = dotenv.env['AI_API_KEY'] ?? dotenv.env['OPENAI_API_KEY'] ?? '';
    if (key.isNotEmpty) {
      OpenAI.apiKey = key;
    }
  }

  /// Executes the ReAct loop yielding real-time [AgentEvent] stream.
  Stream<AgentEvent> run({
    required String userInput,
    required String financialSnapshot,
    required List<Map<String, String>> workingHistory,
    int maxRounds = 4,
  }) async* {
    _ensureConfigured();

    final apiKey = dotenv.env['AI_API_KEY'] ?? dotenv.env['OPENAI_API_KEY'] ?? '';
    if (apiKey.isEmpty) {
      yield const AgentFinalAnswerEvent(
        content: 'Bạn chưa cấu hình OpenAI API Key trong file .env. Vui lòng cấu hình AI_API_KEY=sk-... để sử dụng nhé!',
      );
      return;
    }

    final modelId = dotenv.env['AI_MODEL'] ?? 'gpt-4o-mini';
    final systemPrompt = SystemPromptBuilder.build(financialSnapshot: financialSnapshot);
    final openAiTools = OpenAiToolSpecs.fromRegistry(toolRegistry);

    final messagesList = <OpenAIChatCompletionChoiceMessageModel>[
      OpenAIChatCompletionChoiceMessageModel(
        role: OpenAIChatMessageRole.system,
        content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt)],
      ),
    ];

    // Append bounded working history turns
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

    final collectedActions = <AiExecutedAction>[];
    AiViewPayload? collectedViewPayload;

    for (int round = 1; round <= maxRounds; round++) {
      yield AgentRoundStartedEvent(round: round, maxRounds: maxRounds);
      yield AgentModelCallEvent(round: round, modelId: modelId);

      OpenAIChatCompletionModel chatCompletion;
      try {
        chatCompletion = await OpenAI.instance.chat.create(
          model: modelId,
          messages: messagesList,
          tools: openAiTools.isNotEmpty ? openAiTools : null,
        );
      } catch (e, stack) {
        debugPrint('ReActAgent: Network or API error during chat.create: $e\n$stack');
        yield AgentErrorEvent(errorMessage: 'Lỗi kết nối AI: $e');
        yield AgentFinalAnswerEvent(
          content: 'Xin lỗi bạn, đã có lỗi kết nối khi xử lý yêu cầu. Bạn hãy thử lại nhé!',
          actions: collectedActions,
          viewPayload: collectedViewPayload,
        );
        return;
      }

      final choice = chatCompletion.choices.first;
      final assistantMsg = choice.message;
      final toolCalls = assistantMsg.toolCalls;

      // Case 1: Model finished reasoning (No tool calls requested -> Final Answer or Clarification Question)
      if (toolCalls == null || toolCalls.isEmpty) {
        final contentItems = assistantMsg.content;
        String finalText = '';
        if (contentItems != null && contentItems.isNotEmpty) {
          finalText = contentItems.map((c) => c.text ?? '').join();
        }

        yield AgentFinalAnswerEvent(
          content: finalText.trim(),
          actions: collectedActions,
          viewPayload: collectedViewPayload,
        );
        return;
      }

      // Case 2: Model requested tool calls -> Act & Observe
      messagesList.add(assistantMsg);

      for (final toolCall in toolCalls) {
        final toolName = toolCall.function.name ?? '';
        final rawArgs = toolCall.function.arguments ?? '{}';
        Map<String, dynamic> parsedArgs = {};
        try {
          parsedArgs = jsonDecode(rawArgs) as Map<String, dynamic>;
        } catch (_) {
          parsedArgs = {};
        }

        yield AgentToolExecutionEvent(
          toolName: toolName,
          arguments: parsedArgs,
          toolCallId: toolCall.id,
        );

        AgentToolResult toolResult;
        try {
          final dynamic rawResult = await toolRegistry.dispatch(
            toolName,
            parsedArgs,
            executionContext,
          );

          if (rawResult is AgentToolResult) {
            toolResult = rawResult;
          } else if (rawResult is bool) {
            toolResult = rawResult
                ? AgentToolResult.success(parsedArgs)
                : AgentToolResult.error('Thao tác không thành công', parsedArgs);
          } else if (rawResult is AiViewPayload) {
            toolResult = AgentToolResult.success(parsedArgs, rawResult);
          } else {
            toolResult = AgentToolResult.success(parsedArgs);
          }

          if (toolResult.uiPayload is AiViewPayload) {
            collectedViewPayload = toolResult.uiPayload as AiViewPayload;
          }

          // Build readable executed action for UI presentation
          if (toolResult.isSuccess && !toolName.startsWith('query_') && !toolName.startsWith('view_')) {
            final double amount = (parsedArgs['amount'] as num?)?.toDouble() ?? 0.0;
            final subtitle = parsedArgs['note'] as String? ??
                parsedArgs['walletName'] as String? ??
                parsedArgs['contactName'] as String? ??
                parsedArgs['categoryName'] as String? ??
                '';
            collectedActions.add(
              AiExecutedAction(
                actionType: toolName,
                title: _formatActionTitle(toolName),
                amount: amount,
                subtitle: subtitle,
                date: DateTime.now(),
                isSuccess: true,
                rawAction: parsedArgs,
              ),
            );
          }
        } catch (e) {
          toolResult = AgentToolResult.error('Lỗi khi thực thi công cụ $toolName: $e', parsedArgs);
        }

        yield AgentToolResultEvent(
          toolName: toolName,
          result: toolResult,
          toolCallId: toolCall.id,
        );

        // Feedback observation message into conversation
        final toolObservationJson = jsonEncode(toolResult.toJson());
        final toolMsg = OpenAIChatCompletionChoiceMessageModel(
          toolCalls: [toolCall],
          role: OpenAIChatMessageRole.tool,
          content: [
            OpenAIChatCompletionChoiceMessageContentItemModel.text(toolObservationJson),
          ],
        );

        if (toolCall.id != null) {
          messagesList.add(toolMsg.asRequestFunctionMessage(toolCallId: toolCall.id!));
        } else {
          messagesList.add(toolMsg);
        }
      }
    }

    // If max rounds reached without final answer
    yield AgentFinalAnswerEvent(
      content: 'Đã hoàn tất các thao tác xử lý yêu cầu của bạn.',
      actions: collectedActions,
      viewPayload: collectedViewPayload,
    );
  }

  String _formatActionTitle(String toolName) {
    switch (toolName) {
      case 'transaction_create':
        return 'Giao dịch mới';
      case 'transaction_update':
        return 'Cập nhật giao dịch';
      case 'transaction_delete':
        return 'Xóa giao dịch';
      case 'wallet_create':
        return 'Tạo ví mới';
      case 'wallet_update':
        return 'Cập nhật ví';
      case 'wallet_delete':
        return 'Xóa ví';
      case 'wallet_adjust_balance':
        return 'Điều chỉnh số dư';
      case 'transfer':
        return 'Chuyển tiền ví';
      case 'category_create':
        return 'Tạo danh mục';
      case 'category_update':
        return 'Sửa danh mục';
      case 'category_delete':
        return 'Xóa danh mục';
      case 'budget_set':
        return 'Đặt hạn mức';
      case 'budget_delete':
        return 'Xóa hạn mức';
      case 'loan_create':
        return 'Khoản vay/nợ mới';
      case 'loan_update':
        return 'Cập nhật khoản nợ';
      case 'loan_delete':
        return 'Xóa khoản nợ';
      case 'loan_repay':
        return 'Thanh toán khoản nợ';
      case 'goal_create':
        return 'Tạo mục tiêu tiết kiệm';
      case 'goal_update':
        return 'Cập nhật mục tiêu';
      case 'goal_delete':
        return 'Xóa mục tiêu';
      case 'goal_deposit':
        return 'Góp quỹ tiết kiệm';
      case 'goal_withdraw':
        return 'Rút tiền tiết kiệm';
      case 'recurring_create':
        return 'Lịch giao dịch định kỳ';
      case 'recurring_update':
        return 'Cập nhật định kỳ';
      case 'recurring_delete':
        return 'Hủy lịch định kỳ';
      default:
        return 'Thao tác AI';
    }
  }
}
