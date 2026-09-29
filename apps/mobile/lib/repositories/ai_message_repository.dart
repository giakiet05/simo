import 'package:sqflite/sqflite.dart';
import '../models/ai_message.dart';
import 'database_helper.dart';

/// Repository managing local persistence for conversational AI chat messages.
///
/// Ensures dialogue turns (user questions and corresponding assistant actions/responses)
/// are preserved across application restarts and pruned atomically on a turn-by-turn basis.
class AiMessageRepository {
  final DatabaseHelper _dbHelper;

  AiMessageRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  /// Inserts or replaces a single [AiMessage] in the SQLite database.
  ///
  /// @param message The [AiMessage] to persist.
  /// @returns A [Future] that completes when insertion finishes.
  Future<void> insertMessage(AiMessage message) async {
    final db = await _dbHelper.database;
    await db.insert(
      'ai_messages',
      message.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Inserts a list of [AiMessage]s in a single atomic database batch/transaction.
  ///
  /// @param messages The list of [AiMessage]s to persist.
  /// @returns A [Future] that completes when all insertions finish.
  Future<void> insertMessages(List<AiMessage> messages) async {
    if (messages.isEmpty) return;
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      for (final msg in messages) {
        await txn.insert(
          'ai_messages',
          msg.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });
  }

  /// Fetches messages belonging to the [maxTurns] most recent conversational turns,
  /// ordered chronologically from oldest to newest.
  ///
  /// Complete turns are fetched atomically so user requests and agent responses
  /// are never severed or displayed in isolation.
  ///
  /// @param maxTurns Maximum number of recent complete turns to retrieve (default: 50).
  /// @returns A [Future] with a chronological list of [AiMessage] objects.
  Future<List<AiMessage>> getRecentMessages({int maxTurns = 50}) async {
    final db = await _dbHelper.database;
    final rows = await db.rawQuery('''
      SELECT * FROM ai_messages 
      WHERE turn_id IN (
        SELECT turn_id FROM (
          SELECT turn_id, MAX(timestamp) as max_ts 
          FROM ai_messages 
          GROUP BY turn_id 
          ORDER BY max_ts DESC 
          LIMIT ?
        )
      )
      ORDER BY timestamp ASC
    ''', [maxTurns]);

    return rows.map((row) => AiMessage.fromMap(row)).toList();
  }

  /// Prunes old conversational turns to maintain a maximum of [maxTurns] recent turns.
  ///
  /// Deletions operate on entire turns: when an older user request is pruned,
  /// all associated assistant responses, visual payloads, and action records are deleted together.
  ///
  /// @param maxTurns Maximum number of recent complete turns to retain (default: 50).
  /// @returns Number of pruned message rows.
  Future<int> pruneOldTurns({int maxTurns = 50}) async {
    final db = await _dbHelper.database;
    return await db.rawDelete('''
      DELETE FROM ai_messages 
      WHERE turn_id NOT IN (
        SELECT turn_id FROM (
          SELECT turn_id, MAX(timestamp) as max_ts 
          FROM ai_messages 
          GROUP BY turn_id 
          ORDER BY max_ts DESC 
          LIMIT ?
        )
      )
    ''', [maxTurns]);
  }

  /// Deletes all messages associated with a specific [turnId].
  ///
  /// @param turnId The unique turn identifier to delete.
  /// @returns Number of deleted message rows.
  Future<int> deleteTurn(String turnId) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'ai_messages',
      where: 'turn_id = ?',
      whereArgs: [turnId],
    );
  }

  /// Clears all stored chat messages from the database.
  ///
  /// @returns Number of deleted message rows.
  Future<int> clearAll() async {
    final db = await _dbHelper.database;
    return await db.delete('ai_messages');
  }

  /// Counts the total number of message rows stored in the database.
  ///
  /// @returns Total number of rows.
  Future<int> countMessages() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(*) as total FROM ai_messages');
    if (result.isEmpty) return 0;
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }

  /// Counts the total number of distinct conversational turns stored.
  ///
  /// @returns Total number of distinct turn IDs.
  Future<int> countTurns() async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('SELECT COUNT(DISTINCT turn_id) as total FROM ai_messages');
    if (result.isEmpty) return 0;
    return (result.first['total'] as num?)?.toInt() ?? 0;
  }
}
