import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/wallet.dart';
import '../models/wallet_transfer.dart';
import 'database_helper.dart';

class WalletRepository {
  final DatabaseHelper _dbHelper;
  final _uuid = const Uuid();

  WalletRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<Database> get _db async => await _dbHelper.database;

  Future<List<Wallet>> getAllWallets() async {
    final db = await _db;
    final results = await db.query(
      'wallets',
      orderBy: 'is_default DESC, created_at ASC',
    );
    return results.map((map) => Wallet.fromMap(map)).toList();
  }

  Future<Wallet?> getWalletById(String id) async {
    final db = await _db;
    final results = await db.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return Wallet.fromMap(results.first);
  }

  Future<Wallet?> getDefaultWallet() async {
    final db = await _db;
    final results = await db.query(
      'wallets',
      where: 'is_default = ?',
      whereArgs: [1],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return Wallet.fromMap(results.first);
    }
    final all = await getAllWallets();
    return all.isNotEmpty ? all.first : null;
  }

  Future<void> createWallet(Wallet wallet) async {
    final db = await _db;
    await db.transaction((txn) async {
      if (wallet.isDefault) {
        await txn.update('wallets', {'is_default': 0});
      }

      final walletToInsert = wallet.copyWith(
        currentBalance: wallet.initialBalance,
      );

      await txn.insert(
        'wallets',
        walletToInsert.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
  }

  Future<void> updateWallet(Wallet wallet) async {
    final db = await _db;
    await db.transaction((txn) async {
      if (wallet.isDefault) {
        await txn.update('wallets', {'is_default': 0});
      }

      await txn.update(
        'wallets',
        wallet.toMap(),
        where: 'id = ?',
        whereArgs: [wallet.id],
      );

      // Recalculate balance to reflect initial balance update accurately
      await _recalculateWalletBalanceWithTxn(txn, wallet.id);
    });
  }

  Future<void> deleteWallet(String id) async {
    final db = await _db;
    await db.transaction((txn) async {
      final target = await txn.query(
        'wallets',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      final wasDefault = target.isNotEmpty && (target.first['is_default'] == 1);

      // Nullify wallet_id on associated transactions
      await txn.update(
        'transactions',
        {'wallet_id': null},
        where: 'wallet_id = ?',
        whereArgs: [id],
      );

      // Delete associated transfers
      await txn.delete(
        'wallet_transfers',
        where: 'source_wallet_id = ? OR destination_wallet_id = ?',
        whereArgs: [id, id],
      );

      // Delete wallet
      await txn.delete(
        'wallets',
        where: 'id = ?',
        whereArgs: [id],
      );

      // If deleted wallet was default, pick another wallet as default
      if (wasDefault) {
        final remaining = await txn.query('wallets', limit: 1);
        if (remaining.isNotEmpty) {
          await txn.update(
            'wallets',
            {'is_default': 1},
            where: 'id = ?',
            whereArgs: [remaining.first['id']],
          );
        }
      }
    });
  }

  Future<void> setDefaultWallet(String id) async {
    final db = await _db;
    await db.transaction((txn) async {
      await txn.update('wallets', {'is_default': 0});
      await txn.update(
        'wallets',
        {'is_default': 1},
        where: 'id = ?',
        whereArgs: [id],
      );
    });
  }

  Future<void> transferFunds({
    required String sourceWalletId,
    required String destinationWalletId,
    required double amount,
    double fee = 0.0,
    required DateTime transferDate,
    String? note,
  }) async {
    final db = await _db;
    final transfer = WalletTransfer(
      id: _uuid.v4(),
      sourceWalletId: sourceWalletId,
      destinationWalletId: destinationWalletId,
      amount: amount,
      fee: fee,
      transferDate: transferDate,
      note: note,
      createdAt: DateTime.now(),
    );

    await db.transaction((txn) async {
      await txn.insert('wallet_transfers', transfer.toMap());

      await _recalculateWalletBalanceWithTxn(txn, sourceWalletId);
      await _recalculateWalletBalanceWithTxn(txn, destinationWalletId);
    });
  }

  Future<List<WalletTransfer>> getTransfersForWallet(String walletId) async {
    final db = await _db;
    final results = await db.query(
      'wallet_transfers',
      where: 'source_wallet_id = ? OR destination_wallet_id = ?',
      whereArgs: [walletId, walletId],
      orderBy: 'transfer_date DESC',
    );
    return results.map((map) => WalletTransfer.fromMap(map)).toList();
  }

  Future<List<WalletTransfer>> getAllTransfers() async {
    final db = await _db;
    final results = await db.query(
      'wallet_transfers',
      orderBy: 'transfer_date DESC',
    );
    return results.map((map) => WalletTransfer.fromMap(map)).toList();
  }

  Future<void> deleteTransfer(String transferId) async {
    final db = await _db;
    await db.transaction((txn) async {
      final transferRows = await txn.query(
        'wallet_transfers',
        where: 'id = ?',
        whereArgs: [transferId],
        limit: 1,
      );
      if (transferRows.isEmpty) return;

      final transfer = WalletTransfer.fromMap(transferRows.first);
      await txn.delete(
        'wallet_transfers',
        where: 'id = ?',
        whereArgs: [transferId],
      );

      await _recalculateWalletBalanceWithTxn(txn, transfer.sourceWalletId);
      await _recalculateWalletBalanceWithTxn(txn, transfer.destinationWalletId);
    });
  }

  Future<void> recalculateWalletBalance(String walletId) async {
    final db = await _db;
    await db.transaction((txn) async {
      await _recalculateWalletBalanceWithTxn(txn, walletId);
    });
  }

  Future<void> _recalculateWalletBalanceWithTxn(
    DatabaseExecutor txn,
    String walletId,
  ) async {
    final walletRows = await txn.query(
      'wallets',
      where: 'id = ?',
      whereArgs: [walletId],
      limit: 1,
    );
    if (walletRows.isEmpty) return;

    final initialBalance =
        (walletRows.first['initial_balance'] as num?)?.toDouble() ?? 0.0;

    // Sum transactions for this wallet
    final txResult = await txn.rawQuery('''
      SELECT 
        COALESCE(SUM(CASE WHEN type = 'income' THEN amount ELSE -amount END), 0.0) as balance
      FROM transactions 
      WHERE wallet_id = ?
    ''', [walletId]);
    final txNet = (txResult.first['balance'] as num?)?.toDouble() ?? 0.0;

    // Inflows from transfers
    final inTransferResult = await txn.rawQuery('''
      SELECT COALESCE(SUM(amount), 0.0) as total_in
      FROM wallet_transfers
      WHERE destination_wallet_id = ?
    ''', [walletId]);
    final transferIn =
        (inTransferResult.first['total_in'] as num?)?.toDouble() ?? 0.0;

    // Outflows from transfers (amount + fee)
    final outTransferResult = await txn.rawQuery('''
      SELECT COALESCE(SUM(amount + fee), 0.0) as total_out
      FROM wallet_transfers
      WHERE source_wallet_id = ?
    ''', [walletId]);
    final transferOut =
        (outTransferResult.first['total_out'] as num?)?.toDouble() ?? 0.0;

    final calculatedBalance = initialBalance + txNet + transferIn - transferOut;

    await txn.update(
      'wallets',
      {
        'current_balance': calculatedBalance,
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [walletId],
    );
  }
}
