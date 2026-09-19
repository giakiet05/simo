import 'package:flutter_test/flutter_test.dart';
import 'package:simo/agent/engine/agent_event.dart';
import 'package:simo/agent/engine/react_agent.dart';
import 'package:simo/agent/tools/agent_tool.dart';
import 'package:simo/agent/tools/tool_registry.dart';
import 'package:simo/models/ai_message.dart';

class MockEchoTool extends SimoAgentTool<Map<String, dynamic>, AgentToolResult> {
  @override
  String get name => 'echo_tool';

  @override
  String get description => 'Echoes back the input parameter';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['msg'],
    'properties': {
      'msg': {'type': 'string'},
    },
  };

  @override
  Future<AgentToolResult> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final msg = input['msg'] as String? ?? '';
    if (msg == 'fail') {
      return AgentToolResult.error('Explicit mock failure', input);
    }
    return AgentToolResult.success({'echo': msg});
  }
}

void main() {
  group('AgentEvent & AgentToolResult Tests', () {
    test('AgentToolResult serialization and error feedback', () {
      final success = AgentToolResult.success({'amount': 50000});
      expect(success.isSuccess, isTrue);
      expect(success.data['amount'], equals(50000));
      expect(success.errorMessage, isNull);

      final error = AgentToolResult.error('Insufficient funds in wallet', {'balance': 20000});
      expect(error.isSuccess, isFalse);
      expect(error.errorMessage, equals('Insufficient funds in wallet'));
      expect(error.toJson()['isSuccess'], isFalse);
      expect(error.toJson()['errorMessage'], equals('Insufficient funds in wallet'));
    });

    test('AgentEvent sealed hierarchy instantiations', () {
      const roundStart = AgentRoundStartedEvent(round: 1, maxRounds: 4);
      expect(roundStart.round, equals(1));
      expect(roundStart.maxRounds, equals(4));

      const modelCall = AgentModelCallEvent(round: 1, modelId: 'gpt-5.6-luna');
      expect(modelCall.modelId, equals('gpt-5.6-luna'));

      final toolExec = AgentToolExecutionEvent(
        toolName: 'transfer',
        arguments: {'amount': 100000},
        toolCallId: 'call_123',
      );
      expect(toolExec.toolName, equals('transfer'));
      expect(toolExec.toolCallId, equals('call_123'));

      final toolRes = AgentToolResultEvent(
        toolName: 'transfer',
        result: AgentToolResult.success({'transferred': true}),
        toolCallId: 'call_123',
      );
      expect(toolRes.result.isSuccess, isTrue);

      final finalAnswer = AgentFinalAnswerEvent(
        content: 'Đã chuyển thành công 100.000đ sang MoMo',
        actions: [
          AiExecutedAction(
            actionType: 'transfer',
            title: 'Chuyển tiền ví',
            amount: 100000,
            subtitle: 'Sang MoMo',
            date: DateTime.now(),
            isSuccess: true,
          ),
        ],
      );
      expect(finalAnswer.actions.length, equals(1));
      expect(finalAnswer.content, contains('Đã chuyển thành công'));
    });

    test('ToolRegistry dispatches MockEchoTool returning AgentToolResult', () async {
      final registry = ToolRegistry();
      final tool = MockEchoTool();
      registry.register(tool);

      expect(registry.hasTool('echo_tool'), isTrue);
    });

    test('ReActAgent.buildExtraParams resolves reasoning_effort appropriately', () {
      // 1. gpt-5.6-luna defaults to reasoning_effort = 'none' for tool compatibility
      final lunaParams = ReActAgent.buildExtraParams('gpt-5.6-luna');
      expect(lunaParams, isNotNull);
      expect(lunaParams?['reasoning_effort'], equals('none'));

      // 2. o-series reasoning models default to reasoning_effort = 'none'
      final o1Params = ReActAgent.buildExtraParams('o1-preview');
      expect(o1Params?['reasoning_effort'], equals('none'));

      final o3Params = ReActAgent.buildExtraParams('o3-mini');
      expect(o3Params?['reasoning_effort'], equals('none'));

      // 3. gpt-4o-mini should not include reasoning_effort by default
      final gpt4Params = ReActAgent.buildExtraParams('gpt-4o-mini');
      expect(gpt4Params, isNull);

      // 4. Configured override takes precedence
      final customParams = ReActAgent.buildExtraParams(
        'gpt-5.6-luna',
        configuredEffort: 'low',
      );
      expect(customParams?['reasoning_effort'], equals('low'));

      // 5. Force none overrides any model default
      final forcedParams = ReActAgent.buildExtraParams(
        'gpt-4o',
        forceNoneReasoning: true,
      );
      expect(forcedParams?['reasoning_effort'], equals('none'));
    });

    test('AgentDateHelper.parseDate attaches current time to date-only strings and preserves explicit time', () {
      final reference = DateTime(2026, 9, 19, 14, 35, 20);

      // 1. null or empty input returns reference now
      final nullDate = AgentDateHelper.parseDate(null, reference);
      expect(nullDate, equals(reference));

      final emptyDate = AgentDateHelper.parseDate('   ', reference);
      expect(emptyDate, equals(reference));

      // 2. date-only string (midnight 00:00:00) inherits reference hour/minute/second
      final dateOnly = AgentDateHelper.parseDate('2026-09-19', reference);
      expect(dateOnly.year, equals(2026));
      expect(dateOnly.month, equals(9));
      expect(dateOnly.day, equals(19));
      expect(dateOnly.hour, equals(14));
      expect(dateOnly.minute, equals(35));
      expect(dateOnly.second, equals(20));

      // 3. Past date only string (e.g. yesterday) also inherits reference hour/minute/second
      final yesterday = AgentDateHelper.parseDate('2026-09-18T00:00:00', reference);
      expect(yesterday.year, equals(2026));
      expect(yesterday.month, equals(9));
      expect(yesterday.day, equals(18));
      expect(yesterday.hour, equals(14));
      expect(yesterday.minute, equals(35));
      expect(yesterday.second, equals(20));

      // 4. Explicit non-midnight time is preserved as-is
      final explicitTime = AgentDateHelper.parseDate('2026-09-19T08:15:00', reference);
      expect(explicitTime.hour, equals(8));
      expect(explicitTime.minute, equals(15));
      expect(explicitTime.second, equals(0));
    });
  });
}
