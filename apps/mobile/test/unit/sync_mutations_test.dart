import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:simo/repositories/database_helper.dart';
import 'package:simo/repositories/recurring_repository.dart';
import 'package:simo/repositories/transaction_repository.dart';
import 'package:simo/repositories/wallet_repository.dart';
import 'package:simo/services/sync_service.dart';

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

    test('Updating a transaction can clear an existing note', () async {
      final walletRepo = WalletRepository();
      final txRepo = TransactionRepository(walletRepo: walletRepo);

      final created = await txRepo.createMultiple([
        {
          'amount': 50000.0,
          'type': 'expense',
          'note': 'Initial Note',
        }
      ]);

      final updated = await txRepo.update(created.first.id, note: '');
      final persisted = await txRepo.getById(created.first.id);

      expect(updated.note, isEmpty);
      expect(persisted, isNotNull);
      expect(persisted!.note, isEmpty);
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

    test('Deleting a wallet inserts tombstones for wallet and its transfers and nullifies wallet_id on recurring_configs', () async {
      final walletRepo = WalletRepository();
      final recurringRepo = RecurringRepository();
      final db = await DatabaseHelper.instance.database;

      // Create a test wallet
      final wallets = await walletRepo.getAllWallets();
      final wallet = wallets.first;

      // Create a recurring config bound to this wallet
      final rc = await recurringRepo.create(
        categoryId: null,
        walletId: wallet.id,
        name: 'Internet Bill',
        amount: 330000,
        type: 'expense',
        frequency: 'monthly',
        interval: 1,
      );
      await db.update('recurring_configs', {'synced': 1}, where: 'id = ?', whereArgs: [rc.id]);

      // Delete wallet
      await walletRepo.deleteWallet(wallet.id);

      // Verify tombstone exists
      final tombstones = await db.query('pending_deletions', where: 'cloud_id = ? AND table_name = ?', whereArgs: [wallet.id, 'wallets']);
      expect(tombstones.length, 1);

      // Verify recurring_config has wallet_id nullified and synced reset to 0
      final rcRows = await db.query('recurring_configs', where: 'id = ?', whereArgs: [rc.id]);
      expect(rcRows.length, 1);
      expect(rcRows.first['wallet_id'], isNull);
      expect(rcRows.first['synced'], 0);
    });

    test('SyncService includes already-synced parent wallet when child recurring_config is unsynced and re-keys on ownership conflict', () async {
      SharedPreferences.setMockInitialValues({
        'sync_auth_token': 'test_jwt_token',
        'last_synced_server_time': '2026-09-01T00:00:00Z',
      });

      final walletRepo = WalletRepository();
      final recurringRepo = RecurringRepository();
      final db = await DatabaseHelper.instance.database;

      final wallets = await walletRepo.getAllWallets();
      final defaultWallet = wallets.first;
      // Mark parent wallet as already synced = 1 locally
      await db.update('wallets', {'synced': 1}, where: 'id = ?', whereArgs: [defaultWallet.id]);

      // Create an unsynced recurring config referencing that wallet
      final rc = await recurringRepo.create(
        categoryId: null,
        walletId: defaultWallet.id,
        name: 'Monthly Rent',
        amount: 7000000,
        type: 'expense',
        frequency: 'monthly',
        interval: 1,
      );

      Map<String, dynamic>? capturedRequest;
      final mockHttp = MockClient((request) async {
        capturedRequest = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({
            'data': {
              'server_time': '2026-11-22T10:00:00Z',
              'changes': {
                'wallets': [],
                'wallet_transfers': [],
                'categories': [],
                'transactions': [],
                'monthly_budgets': [],
                'category_monthly_budgets': [],
                'saving_goals': [],
                'saving_goal_logs': [],
                'loan_contacts': [],
                'loan_transactions': [],
                'recurring_configs': [],
                'deletions': [],
              },
              'rejected': [
                {
                  'table': 'wallets',
                  'id': defaultWallet.id,
                  'reason': 'owned_by_another_user',
                }
              ],
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final syncService = SyncService(httpClient: mockHttp);
      final res = await syncService.sync();
      syncService.dispose();

      expect(res.success, isTrue);
      expect(capturedRequest, isNotNull);
      final pushedWallets = (capturedRequest!['mutations'] as Map<String, dynamic>)['wallets'] as List<dynamic>;
      expect(pushedWallets.length, 1);
      expect(pushedWallets.first['id'], defaultWallet.id);

      // Because the server reported defaultWallet.id as owned_by_another_user, it must be re-keyed locally
      final updatedWallets = await db.query('wallets');
      expect(updatedWallets.length, 1);
      final newWalletId = updatedWallets.first['id'] as String;
      expect(newWalletId, isNot(equals(defaultWallet.id)));
      expect(updatedWallets.first['synced'], 0);

      final updatedRc = await db.query('recurring_configs', where: 'id = ?', whereArgs: [rc.id]);
      expect(updatedRc.first['wallet_id'], equals(newWalletId));
      expect(updatedRc.first['synced'], 0);
    });
  });
}
