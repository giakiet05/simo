import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/ai_message.dart';
import 'package:simo/agent/memory/agent_memory_context.dart';
import 'package:simo/agent/brain/protocol_parser.dart';
import 'package:simo/agent/brain/system_prompt_builder.dart';
import 'package:simo/agent/tools/agent_tool.dart';
import 'package:simo/agent/tools/tool_registry.dart';
import 'package:simo/agent/tools/write/category_tools.dart';
import 'package:simo/agent/tools/write/loan_tools.dart';

class MockTestTool extends SimoAgentTool<Map<String, dynamic>, String> {
  @override
  String get name => 'mock_test_tool';

  @override
  String get description => 'Mock tool for testing';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'message': {'type': 'string'},
    },
  };

  @override
  Future<String> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    return 'Executed: ${input['message']}';
  }
}

void main() {
  group('AgentMemoryContext Tests', () {
    test('extractWorkingTurns limits history to exactly 10 turns', () {
      final messages = <AiMessage>[];
      for (int i = 1; i <= 15; i++) {
        messages.add(AiMessage.user('User message $i'));
        messages.add(AiMessage.assistant(content: 'Assistant reply $i'));
      }

      // Total 30 messages
      final workingTurns = AgentMemoryContext.extractWorkingTurns(messages);
      expect(workingTurns.length, equals(10));
      expect(workingTurns.last['content'], equals('Assistant reply 15'));
      expect(workingTurns.first['content'], equals('User message 11'));
    });

    test('calculateHorizonIndex returns null when messages <= 10', () {
      final messages = <AiMessage>[
        AiMessage.user('Msg 1'),
        AiMessage.assistant(content: 'Reply 1'),
        AiMessage.user('Msg 2'),
        AiMessage.assistant(content: 'Reply 2'),
      ];

      final horizon = AgentMemoryContext.calculateHorizonIndex(messages);
      expect(horizon, isNull);
    });

    test('calculateHorizonIndex returns correct index when messages > 10', () {
      final messages = <AiMessage>[];
      for (int i = 1; i <= 12; i++) {
        messages.add(AiMessage.user('User $i'));
      }

      // 12 messages > 10, boundary should be at index 12 - 10 = 2
      final horizon = AgentMemoryContext.calculateHorizonIndex(messages);
      expect(horizon, equals(2));
    });
  });

  group('ProtocolParser Tests', () {
    test('parses valid JSON response with actions and viewQuery', () {
      const rawJson = '''
      {
        "isSuccess": true,
        "responseMessage": "Tôi đã ghi nhận và hiển thị các khoản chi",
        "thought": "Parsed successfully",
        "actions": [
          {
            "actionType": "transaction_create",
            "amount": 50000,
            "type": "expense",
            "note": "phở bò"
          }
        ],
        "viewQuery": {
          "viewType": "query_transactions",
          "period": "today"
        }
      }
      ''';

      final result = ProtocolParser.parse(rawJson);
      expect(result.isSuccess, isTrue);
      expect(result.responseMessage, equals('Tôi đã ghi nhận và hiển thị các khoản chi'));
      expect(result.actions.length, equals(1));
      expect(result.actions.first['actionType'], equals('transaction_create'));
      expect(result.actions.first['amount'], equals(50000));
      expect(result.viewQuery?['viewType'], equals('query_transactions'));
    });

    test('falls back gracefully on non-JSON raw text without crashing', () {
      const rawText = 'Đã ghi nhận khoản vay mới 70.000 VND cho Nam.';
      final result = ProtocolParser.parse(rawText);

      expect(result.isSuccess, isTrue);
      expect(result.responseMessage, equals(rawText));
      expect(result.actions, isEmpty);
      expect(result.viewQuery, isNull);
    });
  });

  group('SystemPromptBuilder Tests', () {
    test('builds prompt containing all tool specifications and currency rules', () {
      final prompt = SystemPromptBuilder.build(financialSnapshot: 'Ví tiền mặt: 100.000 VND');
      expect(prompt.contains('transaction_create'), isTrue);
      expect(prompt.contains('transaction_update'), isTrue);
      expect(prompt.contains('transaction_delete'), isTrue);
      expect(prompt.contains('budget_set'), isTrue);
      expect(prompt.contains('wallet_create'), isTrue);
      expect(prompt.contains('category_create'), isTrue);
      expect(prompt.contains('category_update'), isTrue);
      expect(prompt.contains('category_delete'), isTrue);
      expect(prompt.contains('query_transactions'), isTrue);
      expect(prompt.contains('view_budgets'), isTrue);
      expect(prompt.contains('navigate_screen'), isTrue);
      expect(prompt.contains('Ví tiền mặt: 100.000 VND'), isTrue);
    });
  });

  group('CategoryResolverHelper Tests', () {
    test('resolves named colors and hex codes accurately', () {
      expect(CategoryResolverHelper.resolveColor('đỏ', 'expense'), equals('#EF4444'));
      expect(CategoryResolverHelper.resolveColor('xanh lá', 'expense'), equals('#10B981'));
      expect(CategoryResolverHelper.resolveColor('tím', 'expense'), equals('#8B5CF6'));
      expect(CategoryResolverHelper.resolveColor('#123456', 'expense'), equals('#123456'));
      expect(CategoryResolverHelper.resolveColor(null, 'income'), equals('#10B981'));
    });

    test('resolves semantic keywords into valid icons', () {
      expect(CategoryResolverHelper.resolveIcon(null, 'Quậy', 'expense'), equals('celebration'));
      expect(CategoryResolverHelper.resolveIcon(null, 'Đi nhậu', 'expense'), equals('celebration'));
      expect(CategoryResolverHelper.resolveIcon(null, 'Cà phê sáng', 'expense'), equals('coffee'));
      expect(CategoryResolverHelper.resolveIcon(null, 'Đổ xăng xe', 'expense'), equals('local_gas_station'));
      expect(CategoryResolverHelper.resolveIcon(null, 'Chơi game', 'expense'), equals('sports_esports'));
      expect(CategoryResolverHelper.resolveIcon('local_bar', 'Hội họp', 'expense'), equals('local_bar'));
    });
  });

  group('Category Tools Schema Tests', () {
    test('CreateCategoryTool and UpdateCategoryTool schemas and names', () {
      final createCatTool = CreateCategoryTool();
      expect(createCatTool.name, equals('category_create'));
      expect(createCatTool.parametersSchema['required'], contains('categoryName'));
      expect(createCatTool.parametersSchema['properties'], contains('budgetLimit'));

      final updateCatTool = UpdateCategoryTool();
      expect(updateCatTool.name, equals('category_update'));
      expect(updateCatTool.parametersSchema['properties'], contains('newName'));
    });
  });

  group('ToolRegistry Tests', () {
    test('registers and retrieves tool by name', () {
      final registry = ToolRegistry();
      final tool = MockTestTool();
      registry.register(tool);

      expect(registry.hasTool('mock_test_tool'), isTrue);
      expect(registry.getTool('mock_test_tool'), equals(tool));
    });
  });

  group('Loan Tools Schema and ToolRegistry Tests', () {
    test('CreateLoanTool and RepayLoanTool have valid schemas and names', () {
      final createLoanTool = CreateLoanTool();
      expect(createLoanTool.name, equals('loan_create'));
      expect(createLoanTool.parametersSchema['required'], contains('amount'));
      expect(createLoanTool.parametersSchema['required'], contains('contactName'));

      final repayLoanTool = RepayLoanTool();
      expect(repayLoanTool.name, equals('loan_repay'));
      expect(repayLoanTool.parametersSchema['required'], contains('amount'));
    });

    test('ToolRegistry registers and finds loan tools', () {
      final registry = ToolRegistry();
      registry.register(CreateLoanTool());
      registry.register(RepayLoanTool());

      expect(registry.hasTool('loan_create'), isTrue);
      expect(registry.hasTool('loan_repay'), isTrue);
    });
  });

  group('AiMessage with AiViewPayload Tests', () {
    test('AiMessage stores and retrieves TransactionListViewPayload', () {
      final payload = TransactionListViewPayload(
        title: 'Giao dịch hôm nay',
        totalAmount: 150000,
        period: 'today',
        transactions: [
          TransactionItemViewData(
            id: 'tx_1',
            amount: 50000,
            type: 'expense',
            note: 'Cà phê',
            categoryName: 'Ăn uống',
            categoryIcon: 'coffee',
            categoryColor: '#FF9800',
            walletName: 'Momo',
            date: DateTime.now(),
          ),
        ],
      );

      final message = AiMessage.assistant(
        content: 'Đây là danh sách chi tiêu hôm nay',
        viewPayload: payload,
      );

      expect(message.viewPayload, isA<TransactionListViewPayload>());
      final casted = message.viewPayload as TransactionListViewPayload;
      expect(casted.totalAmount, equals(150000));
      expect(casted.transactions.first.note, equals('Cà phê'));
    });
  });
}
