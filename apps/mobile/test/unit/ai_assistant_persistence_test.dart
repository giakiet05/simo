import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:simo/models/ai_message.dart';
import 'package:simo/providers/ai_assistant_provider.dart';
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

  group('AiAssistant Persistence Integration Tests', () {
    late AiMessageRepository repo;

    setUp(() {
      repo = AiMessageRepository();
    });

    test('AiAssistantNotifier loads persisted chat messages upon initialization', () async {
      // Pre-populate repository with 2 turns
      final user1 = AiMessage.user('Nạp 500k vào mục tiêu mua xe', turnId: 'turn-1', timestamp: DateTime(2026, 9, 30, 8, 0));
      final asst1 = AiMessage.assistant(content: 'Đã nạp 500k vào mục tiêu mua xe', turnId: 'turn-1', timestamp: DateTime(2026, 9, 30, 8, 1));
      final user2 = AiMessage.user('Ví tiền mặt còn bao nhiêu?', turnId: 'turn-2', timestamp: DateTime(2026, 9, 30, 8, 2));
      final asst2 = AiMessage.assistant(content: 'Ví tiền mặt còn 2.500.000đ', turnId: 'turn-2', timestamp: DateTime(2026, 9, 30, 8, 3));

      await repo.insertMessage(user1);
      await repo.insertMessage(asst1);
      await repo.insertMessage(user2);
      await repo.insertMessage(asst2);

      // Create a container with mocked/instantiated provider
      final container = ProviderContainer(
        overrides: [
          aiMessageRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);

      // Wait a microtask / pump for asynchronous _loadPersistedMessages to finish
      final notifier = container.read(aiAssistantProvider.notifier);
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(aiAssistantProvider);
      expect(state.messages.length, equals(4));
      expect(state.messages[0].content, equals('Nạp 500k vào mục tiêu mua xe'));
      expect(state.messages[1].content, equals('Đã nạp 500k vào mục tiêu mua xe'));
      expect(state.messages[2].content, equals('Ví tiền mặt còn bao nhiêu?'));
      expect(state.messages[3].content, equals('Ví tiền mặt còn 2.500.000đ'));

      // Test clearChat clears both state and database
      await notifier.clearChat();
      final clearedState = container.read(aiAssistantProvider);
      expect(clearedState.messages.isEmpty, isTrue);

      final countInDb = await repo.countMessages();
      expect(countInDb, equals(0));
    });
  });
}
