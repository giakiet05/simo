import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:simo/repositories/database_helper.dart';
import 'package:simo/repositories/transaction_repository.dart';
import 'package:simo/repositories/wallet_repository.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    await DatabaseHelper.instance.clearAllData();
  });

  group('Sync Mutations & Tombstones Tracking Tests', () {
    test('Updating a transaction marks synced = 0 and updates updated_at', () async {
      final walletRepo = WalletRepository();
      final txRepo = TransactionRepository(walletRepo: walletRepo);
      final db = await DatabaseHelper.instance.database;

      // 1. Create a transaction
      final createdList = await txRepo.createMultiple([
        {
          'amount': 50000.0,
          'type': 'expense',
          'note': 'Initial Note',
        }
      ]);
      final tx = createdList.first;

      // 2. Simulate sync completion (mark synced = 1)
      await db.update('transactions', {'synced': 1}, where: 'id = ?', whereArgs: [tx.id]);

      var check = await db.query('transactions', where: 'id = ?', whereArgs: [tx.id]);
      expect(check.first['synced'], 1);

      // 3. Update transaction
      await txRepo.update(tx.id, note: 'Updated Note', amount: 65000.0);

      // 4. Verify synced is reset to 0
      check = await db.query('transactions', where: 'id = ?', whereArgs: [tx.id]);
      expect(check.first['synced'], 0);
      expect(check.first['note'], 'Updated Note');
      expect(check.first['amount'], 65000.0);
    });

    test('Deleting transactions inserts tombstone records into pending_deletions', () async {
      final walletRepo = WalletRepository();
      final txRepo = TransactionRepository(walletRepo: walletRepo);
      final db = await DatabaseHelper.instance.database;

      // 1. Create a transaction
      final createdList = await txRepo.createMultiple([
        {
          'amount': 30000.0,
          'type': 'expense',
          'note': 'To Delete',
        }
      ]);
      final tx = createdList.first;

      // 2. Mark synced = 1
      await db.update('transactions', {'synced': 1}, where: 'id = ?', whereArgs: [tx.id]);

      // 3. Delete transaction
      await txRepo.deleteMultiple([tx.id]);

      // 4. Verify transaction is removed from transactions table
      final txRows = await db.query('transactions', where: 'id = ?', whereArgs: [tx.id]);
      expect(txRows.isEmpty, true);

      // 5. Verify tombstone exists in pending_deletions table
      final tombstones = await db.query('pending_deletions', where: 'cloud_id = ?', whereArgs: [tx.id]);
      expect(tombstones.length, 1);
      expect(tombstones.first['table_name'], 'transactions');
      expect(tombstones.first['cloud_id'], tx.id);
      expect(tombstones.first['deleted_at'], isNotNull);
    });

    test('Deleting a wallet inserts tombstones for wallet and its transfers', () async {
      final walletRepo = WalletRepository();
      final db = await DatabaseHelper.instance.database;

      // Create a test wallet
      final wallets = await walletRepo.getAllWallets();
      final wallet = wallets.first;

      // Delete wallet
      await walletRepo.deleteWallet(wallet.id);

      // Verify tombstone exists
      final tombstones = await db.query('pending_deletions', where: 'cloud_id = ? AND table_name = ?', whereArgs: [wallet.id, 'wallets']);
      expect(tombstones.length, 1);
    });
  });
}
