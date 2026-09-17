import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/ai_message.dart';

void main() {
  group('AiMessage and AiExecutedAction Tests', () {
    test('AiMessage.user initializes with correct defaults', () {
      final message = AiMessage.user('Ăn sáng 45k');
      expect(message.role, equals(AiMessageRole.user));
      expect(message.content, equals('Ăn sáng 45k'));
      expect(message.status, equals(AiMessageStatus.idle));
      expect(message.actions, isEmpty);
    });

    test('AiMessage.assistantThinking initializes with thinking status', () {
      final message = AiMessage.assistantThinking();
      expect(message.role, equals(AiMessageRole.assistant));
      expect(message.content, isEmpty);
      expect(message.status, equals(AiMessageStatus.thinking));
    });

    test('AiMessage.assistant initializes with content and executed actions', () {
      final action = AiExecutedAction(
        actionType: 'transaction',
        title: 'Chi tiêu',
        amount: 45000,
        subtitle: 'Ăn uống • Tiền mặt',
        date: DateTime(2026, 9, 17),
        isSuccess: true,
      );

      final message = AiMessage.assistant(
        content: 'Đã lưu khoản chi 45.000đ!',
        actions: [action],
      );

      expect(message.role, equals(AiMessageRole.assistant));
      expect(message.content, equals('Đã lưu khoản chi 45.000đ!'));
      expect(message.status, equals(AiMessageStatus.executed));
      expect(message.actions.length, equals(1));
      expect(message.actions.first.amount, equals(45000));
    });

    test('AiExecutedAction.fromRawAction parses dictionary correctly', () {
      final raw = {
        'actionType': 'transfer',
        'amount': 500000,
        'date': '2026-09-17T12:00:00.000Z',
        'note': 'Chuyển quỹ',
      };

      final action = AiExecutedAction.fromRawAction(
        rawAction: raw,
        title: 'Chuyển khoản ví',
        subtitle: 'Techcombank -> MoMo',
      );

      expect(action.actionType, equals('transfer'));
      expect(action.amount, equals(500000.0));
      expect(action.title, equals('Chuyển khoản ví'));
      expect(action.subtitle, equals('Techcombank -> MoMo'));
      expect(action.isSuccess, isTrue);
    });
  });
}
