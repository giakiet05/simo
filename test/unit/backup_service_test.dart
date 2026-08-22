import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart' hide Transaction;
import 'package:simo/repositories/database_helper.dart';
import 'package:simo/services/backup_service.dart';
import 'package:simo/repositories/category_repository.dart';
import 'package:simo/repositories/transaction_repository.dart';
import 'package:simo/models/transaction.dart';

import 'package:flutter/services.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

  tearDown(() async {
    await DatabaseHelper.instance.clearAllData();
  });

  group('BackupService Tests', () {
    late BackupService backupService;
    late CategoryRepository categoryRepo;
    late TransactionRepository txRepo;

    setUp(() {
      backupService = BackupService();
      categoryRepo = CategoryRepository();
      txRepo = TransactionRepository();
    });

    test('creates valid backup snapshot and inspects counts correctly', () async {
      final cat = await categoryRepo.create('Ăn uống', 'expense');
      final tx = Transaction(
        id: 'tx_test_1',
        amount: 45000,
        type: 'expense',
        categoryId: cat.id,
        note: 'Bún bò',
        transactionDate: DateTime(2026, 8, 22),
        createdAt: DateTime(2026, 8, 22),
        updatedAt: DateTime(2026, 8, 22),
      );
      final db = await DatabaseHelper.instance.database;
      await db.insert('transactions', tx.toMap());

      final file = await backupService.createBackupFile();
      expect(await file.exists(), isTrue);

      final inspection = await backupService.inspectBackupFile(file);
      expect(inspection.isValid, isTrue);
      expect(inspection.totalCategories, greaterThanOrEqualTo(1));
      expect(inspection.totalTransactions, greaterThanOrEqualTo(1));

      // Clean up temp file
      if (await file.exists()) {
        await file.delete();
      }
    });

    test('restores database from backup snapshot with overwrite mode', () async {
      final cat = await categoryRepo.create('Mua sắm', 'expense');
      final tx = Transaction(
        id: 'tx_test_2',
        amount: 200000,
        type: 'expense',
        categoryId: cat.id,
        note: 'Áo thun',
        transactionDate: DateTime(2026, 8, 22),
        createdAt: DateTime(2026, 8, 22),
        updatedAt: DateTime(2026, 8, 22),
      );
      final db = await DatabaseHelper.instance.database;
      await db.insert('transactions', tx.toMap());

      // Create backup
      final backupFile = await backupService.createBackupFile();

      // Clear all data
      await DatabaseHelper.instance.clearAllData();
      final emptyTxs = await txRepo.getAll();
      expect(emptyTxs.isEmpty, isTrue);

      // Restore
      final restored = await backupService.restoreFromBackup(backupFile, overwriteMode: true);
      expect(restored, isTrue);

      // Verify data is back
      final restoredTxs = await txRepo.getAll();
      expect(restoredTxs.length, equals(1));
      expect(restoredTxs.first.note, equals('Áo thun'));

      if (await backupFile.exists()) {
        await backupFile.delete();
      }
    });

    test('handles invalid/corrupted backup files safely', () async {
      final tempFile = File('${Directory.systemTemp.path}/corrupt_test.json');
      await tempFile.writeAsString('{"invalid": "json format without schema"}');

      final inspection = await backupService.inspectBackupFile(tempFile);
      expect(inspection.isValid, isFalse);
      expect(inspection.errorMessage, isNotNull);

      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    });
  });
}
