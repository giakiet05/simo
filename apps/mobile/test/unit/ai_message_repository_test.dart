import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:simo/models/ai_message.dart';
import 'package:simo/repositories/database_helper.dart';
import 'package:simo/repositories/ai_message_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.clearAllData();
  });

  group('AiMessageRepository Tests', () {
    late AiMessageRepository repo;

    setUp(() {
      repo = AiMessageRepository();
    });

    test('inserts and retrieves messages preserving turnId and order', () async {
      const turn1 = 'turn-001';
      final userMsg = AiMessage.user(
        'Ăn sáng 35k ví tiền mặt',
        turnId: turn1,
        timestamp: DateTime(2026, 9, 30, 8, 0, 0),
      );
      final asstMsg = AiMessage.assistant(
        content: 'Đã ghi nhận chi tiêu ăn sáng 35.000đ',
        turnId: turn1,
        timestamp: DateTime(2026, 9, 30, 8, 0, 2),
        actions: [
          AiExecutedAction(
            actionType: 'transaction_create',
            title: 'Chi tiêu',
            amount: 35000.0,
            subtitle: 'Ăn uống - Ví tiền mặt',
            date: DateTime(2026, 9, 30, 8, 0, 0),
            isSuccess: true,
          ),
        ],
      );

      await repo.insertMessage(userMsg);
      await repo.insertMessage(asstMsg);

      final messages = await repo.getRecentMessages(maxTurns: 10);
      expect(messages.length, equals(2));
      expect(messages[0].turnId, equals(turn1));
      expect(messages[0].role, equals(AiMessageRole.user));
      expect(messages[0].content, equals('Ăn sáng 35k ví tiền mặt'));

      expect(messages[1].turnId, equals(turn1));
      expect(messages[1].role, equals(AiMessageRole.assistant));
      expect(messages[1].actions.length, equals(1));
      expect(messages[1].actions[0].amount, equals(35000.0));
      expect(messages[1].actions[0].title, equals('Chi tiêu'));
    });

    test('prunes old turns atomically without leaving orphaned questions or responses', () async {
      // Insert 5 complete turns (turn 1 to 5)
      for (int i = 1; i <= 5; i++) {
        final tid = 'turn-00$i';
        final userMsg = AiMessage.user(
          'Question $i',
          turnId: tid,
          timestamp: DateTime(2026, 9, 30, 8, i, 0),
        );
        final asstMsg = AiMessage.assistant(
          content: 'Response $i',
          turnId: tid,
          timestamp: DateTime(2026, 9, 30, 8, i, 3),
        );
        await repo.insertMessage(userMsg);
        await repo.insertMessage(asstMsg);
      }

      expect(await repo.countMessages(), equals(10));
      expect(await repo.countTurns(), equals(5));

      // Prune to keep only 3 most recent turns (turn 3, 4, 5)
      final prunedRows = await repo.pruneOldTurns(maxTurns: 3);
      expect(prunedRows, equals(4)); // 2 turns * 2 messages = 4 rows deleted

      expect(await repo.countMessages(), equals(6));
      expect(await repo.countTurns(), equals(3));

      final remaining = await repo.getRecentMessages(maxTurns: 10);
      expect(remaining.length, equals(6));

      // Verify oldest turns (1 and 2) are completely gone
      final remainingTurnIds = remaining.map((m) => m.turnId).toSet();
      expect(remainingTurnIds, contains('turn-003'));
      expect(remainingTurnIds, contains('turn-004'));
      expect(remainingTurnIds, contains('turn-005'));
      expect(remainingTurnIds, isNot(contains('turn-001')));
      expect(remainingTurnIds, isNot(contains('turn-002')));

      // Verify each turn has both user and assistant intact
      for (final tid in remainingTurnIds) {
        final msgsForTurn = remaining.where((m) => m.turnId == tid).toList();
        expect(msgsForTurn.length, equals(2));
        expect(msgsForTurn[0].role, equals(AiMessageRole.user));
        expect(msgsForTurn[1].role, equals(AiMessageRole.assistant));
      }
    });

    test('deleteTurn removes both user request and assistant responses for that turn', () async {
      const tid = 'turn-target-delete';
      await repo.insertMessage(AiMessage.user('Test query', turnId: tid));
      await repo.insertMessage(AiMessage.assistant(content: 'Test answer', turnId: tid));

      expect(await repo.countMessages(), equals(2));
      final deleted = await repo.deleteTurn(tid);
      expect(deleted, equals(2));
      expect(await repo.countMessages(), equals(0));
    });

    test('clearAll removes all persisted chat records', () async {
      await repo.insertMessage(AiMessage.user('Query 1', turnId: 't1'));
      await repo.insertMessage(AiMessage.assistant(content: 'Answer 1', turnId: 't1'));
      await repo.insertMessage(AiMessage.user('Query 2', turnId: 't2'));

      expect(await repo.countMessages(), equals(3));
      await repo.clearAll();
      expect(await repo.countMessages(), equals(0));
      expect(await repo.countTurns(), equals(0));
    });
  });
}
