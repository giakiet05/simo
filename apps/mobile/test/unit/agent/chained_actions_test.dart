import 'package:flutter_test/flutter_test.dart';
import 'package:simo/agent/engine/agent_event.dart';
import 'package:simo/models/ai_message.dart';

void main() {
  group('Chained Actions & Multi-Action Batching Tests', () {
    test('aggregates sequential tool execution results into final answer actions', () {
      final actions = <AiExecutedAction>[
        AiExecutedAction(
          actionType: 'category_create',
          title: 'Tạo danh mục',
          amount: 0,
          subtitle: 'Nuôi mèo',
          date: DateTime.now(),
          isSuccess: true,
        ),
        AiExecutedAction(
          actionType: 'transaction_create',
          title: 'Giao dịch mới',
          amount: 250000,
          subtitle: 'Mua hạt mèo',
          date: DateTime.now(),
          isSuccess: true,
        ),
      ];

      final finalAnswer = AgentFinalAnswerEvent(
        content: 'Đã tạo danh mục Nuôi mèo và ghi nhận chi tiêu 250.000đ cho bạn.',
        actions: actions,
      );

      expect(finalAnswer.actions.length, equals(2));
      expect(finalAnswer.actions.first.actionType, equals('category_create'));
      expect(finalAnswer.actions.last.actionType, equals('transaction_create'));
      expect(finalAnswer.actions.last.amount, equals(250000));
    });

    test('AgentToolResult preserves diagnostic metadata across chained rounds', () {
      final round1Result = AgentToolResult.success({'categoryId': 'cat_cat_care', 'categoryName': 'Nuôi mèo'});
      expect(round1Result.isSuccess, isTrue);
      expect(round1Result.data['categoryId'], equals('cat_cat_care'));

      final round2Result = AgentToolResult.success({
        'transactionId': 'tx_123',
        'categoryId': round1Result.data['categoryId'],
        'amount': 250000,
      });

      expect(round2Result.isSuccess, isTrue);
      expect(round2Result.data['categoryId'], equals('cat_cat_care'));
      expect(round2Result.data['amount'], equals(250000));
    });
  });
}
