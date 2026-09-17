import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Structured outcome of the Agent Brain LLM invocation.
class AgentBrainResult {
  final bool isSuccess;
  final String responseMessage;
  final String thought;
  final List<Map<String, dynamic>> actions;
  final Map<String, dynamic>? viewQuery;

  const AgentBrainResult({
    required this.isSuccess,
    required this.responseMessage,
    required this.thought,
    this.actions = const [],
    this.viewQuery,
  });
}

/// Parses raw text responses from the LLM into structured [AgentBrainResult] with graceful fallback.
class ProtocolParser {
  /// Parses raw LLM text string into typed [AgentBrainResult].
  static AgentBrainResult parse(String rawText) {
    if (rawText.trim().isEmpty) {
      return const AgentBrainResult(
        isSuccess: false,
        responseMessage: 'Không nhận được phản hồi từ AI.',
        thought: 'Empty response',
      );
    }

    var cleanJson = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
    final startIndex = cleanJson.indexOf('{');
    final endIndex = cleanJson.lastIndexOf('}');
    if (startIndex != -1 && endIndex != -1 && startIndex < endIndex) {
      cleanJson = cleanJson.substring(startIndex, endIndex + 1);
    }

    Map<String, dynamic> jsonMap;
    try {
      jsonMap = jsonDecode(cleanJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('ProtocolParser: Non-JSON response, fallback to text: $rawText');
      return AgentBrainResult(
        isSuccess: true,
        responseMessage: rawText,
        thought: 'Raw text fallback',
      );
    }

    final isSuccess = jsonMap['isSuccess'] as bool? ?? true;
    final thought = jsonMap['thought'] as String? ?? '';
    final responseMessage = jsonMap['responseMessage'] as String? ??
        jsonMap['message'] as String? ??
        'Tôi đã ghi nhận yêu cầu của bạn!';

    // Normalize actions
    final rawActions = jsonMap['actions'] as List<dynamic>? ?? [];
    final normalizedActions = <Map<String, dynamic>>[];

    for (final act in rawActions) {
      if (act is! Map<String, dynamic>) continue;
      final copy = Map<String, dynamic>.from(act);
      var type = copy['actionType'] as String? ?? 'transaction_create';
      // Normalize legacy action types
      if (type == 'transaction') type = 'transaction_create';
      copy['actionType'] = type;
      normalizedActions.add(copy);
    }

    // Extract viewQuery if present
    Map<String, dynamic>? viewQuery;
    if (jsonMap.containsKey('viewQuery') && jsonMap['viewQuery'] is Map<String, dynamic>) {
      final vq = jsonMap['viewQuery'] as Map<String, dynamic>;
      if (vq['viewType'] != null) {
        viewQuery = vq;
      }
    }

    return AgentBrainResult(
      isSuccess: isSuccess,
      responseMessage: responseMessage,
      thought: thought,
      actions: normalizedActions,
      viewQuery: viewQuery,
    );
  }
}
