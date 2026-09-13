import 'dart:async';
import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../repositories/database_helper.dart';

/// SyncResult encapsulates the outcome of a synchronization cycle.
class SyncResult {
  final bool success;
  final String message;
  final int pushedCount;
  final int pulledCount;
  final DateTime? serverTime;

  SyncResult({
    required this.success,
    required this.message,
    this.pushedCount = 0,
    this.pulledCount = 0,
    this.serverTime,
  });
}

/// SyncService coordinates two-way delta synchronization between local SQLite and Go backend.
class SyncService {
  final DatabaseHelper _dbHelper;
  final http.Client _httpClient;
  Timer? _debounceTimer;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  SyncService({
    DatabaseHelper? dbHelper,
    http.Client? httpClient,
  })  : _dbHelper = dbHelper ?? DatabaseHelper.instance,
        _httpClient = httpClient ?? http.Client();

  /// Returns the persistent unique client device identifier.
  Future<String> getDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? deviceId = prefs.getString('sync_device_id');
    if (deviceId == null) {
      deviceId = const Uuid().v4();
      await prefs.setString('sync_device_id', deviceId);
    }
    return deviceId;
  }

  /// Returns the configured Sync API Base URL.
  Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sync_api_base_url') ??
        (dotenv.isInitialized ? dotenv.env['SYNC_API_BASE_URL'] : null) ??
        'https://simo-api.giakiet.io.vn/api/v1';
  }

  /// Returns the configured Auth token.
  Future<String> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('sync_auth_token') ??
        prefs.getString('auth_session_token') ??
        'dev_token';
  }

  /// Starts listening for network recovery to trigger auto-sync.
  void startNetworkMonitoring(VoidCallback onNetworkRestored) {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      final isOnline = results.any((r) => r != ConnectivityResult.none);
      if (isOnline && !_isSyncing) {
        debugPrint('[SyncService] Network restored. Triggering auto-sync...');
        onNetworkRestored();
      }
    });
  }

  /// Disposes background timers and stream listeners.
  void dispose() {
    _debounceTimer?.cancel();
    _connectivitySubscription?.cancel();
  }

  /// Triggers a debounced synchronization after a local data mutation (500ms delay).
  void triggerDebouncedSync({VoidCallback? onSyncCompleted}) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () async {
      debugPrint('[SyncService] Debounce expired. Executing mutation sync...');
      final result = await sync();
      if (result.success && onSyncCompleted != null) {
        onSyncCompleted();
      }
    });
  }

  /// Executes the full-duplex Push-First Pull-Second synchronization cycle.
  Future<SyncResult> sync({
    String? customBaseUrl,
    String? customToken,
  }) async {
    if (_isSyncing) {
      return SyncResult(success: false, message: 'Sync is already in progress');
    }

    _isSyncing = true;
    try {
      final db = await _dbHelper.database;
      final prefs = await SharedPreferences.getInstance();
      final deviceId = await getDeviceId();
      final baseUrl = customBaseUrl ?? await getBaseUrl();
      final token = customToken ?? await getAuthToken();
      if (token == null || token.isEmpty) {
        _isSyncing = false;
        return SyncResult(success: false, message: 'Chưa đăng nhập');
      }
      final lastSyncedTimeStr = prefs.getString('last_synced_server_time');

      // 1. Gather all local unsynced mutations
      final unsyncedWallets = await db.query('wallets', where: 'synced = 0 OR synced IS NULL');
      final unsyncedCategories = await db.query('categories', where: 'synced = 0 OR synced IS NULL');
      final unsyncedTransactions = await db.query('transactions', where: 'synced = 0 OR synced IS NULL');
      final unsyncedTransfers = await db.query('wallet_transfers', where: 'synced = 0 OR synced IS NULL');
      final unsyncedBudgets = await db.query('monthly_budgets', where: 'synced = 0 OR synced IS NULL');
      final unsyncedCatBudgets = await db.query('category_monthly_budgets', where: 'synced = 0 OR synced IS NULL');
      final unsyncedGoals = await db.query('saving_goals', where: 'synced = 0 OR synced IS NULL');
      final unsyncedGoalLogs = await db.query('saving_goal_logs', where: 'synced = 0 OR synced IS NULL');
      final unsyncedLoans = await db.query('loan_contacts', where: 'synced = 0 OR synced IS NULL');
      final unsyncedLoanTx = await db.query('loan_transactions', where: 'synced = 0 OR synced IS NULL');
      final unsyncedRecurring = await db.query('recurring_configs', where: 'synced = 0 OR synced IS NULL');
      final pendingDeletions = await db.query('pending_deletions');

      final mutations = {
        'wallets': unsyncedWallets.map((w) => _formatWalletForSync(w)).toList(),
        'categories': unsyncedCategories.map((c) => _formatCategoryForSync(c)).toList(),
        'transactions': unsyncedTransactions.map((t) => _formatTransactionForSync(t)).toList(),
        'wallet_transfers': unsyncedTransfers.map((wt) => _formatTransferForSync(wt)).toList(),
        'monthly_budgets': unsyncedBudgets.map((mb) => _formatBudgetForSync(mb)).toList(),
        'category_monthly_budgets': unsyncedCatBudgets.map((cmb) => _formatCatBudgetForSync(cmb)).toList(),
        'saving_goals': unsyncedGoals.map((sg) => _formatGoalForSync(sg)).toList(),
        'saving_goal_logs': unsyncedGoalLogs.map((sgl) => _formatGoalLogForSync(sgl)).toList(),
        'loan_contacts': unsyncedLoans.map((lc) => _formatLoanForSync(lc)).toList(),
        'loan_transactions': unsyncedLoanTx.map((lt) => _formatLoanTxForSync(lt)).toList(),
        'recurring_configs': unsyncedRecurring.map((rc) => _formatRecurringForSync(rc)).toList(),
        'deletions': pendingDeletions.map((d) => {
              'table_name': d['table_name'],
              'id': d['cloud_id'] ?? d['id'].toString(),
              'deleted_at': _formatIsoUtcRequired(d['deleted_at']),
            }).toList(),
      };

      final requestPayload = {
        'last_synced_server_time': _formatIsoUtc(lastSyncedTimeStr),
        'device_id': deviceId,
        'mutations': mutations,
      };

      final int pushedCount = unsyncedWallets.length +
          unsyncedCategories.length +
          unsyncedTransactions.length +
          unsyncedTransfers.length +
          unsyncedBudgets.length +
          unsyncedCatBudgets.length +
          unsyncedGoals.length +
          unsyncedGoalLogs.length +
          unsyncedLoans.length +
          unsyncedLoanTx.length +
          unsyncedRecurring.length +
          pendingDeletions.length;

      debugPrint('================ [SyncService Request] ================');
      debugPrint('Target: POST $baseUrl/sync');
      debugPrint('Pushed Mutations Count: $pushedCount');
      debugPrint('Payload: ${jsonEncode(requestPayload)}');

      // 2. Call POST /api/v1/sync
      final response = await _httpClient.post(
        Uri.parse('$baseUrl/sync'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestPayload),
      ).timeout(const Duration(seconds: 15));

      debugPrint('================ [SyncService Response] ================');
      debugPrint('HTTP Status: ${response.statusCode}');
      debugPrint('HTTP Body: ${response.body}');

      if (response.statusCode != 200) {
        return SyncResult(
          success: false,
          message: 'Server returned status ${response.statusCode}: ${response.body}',
        );
      }

      final responseJson = jsonDecode(response.body) as Map<String, dynamic>;
      final data = responseJson['data'] as Map<String, dynamic>;
      final serverTimeStr = data['server_time'] as String;
      final changes = data['changes'] as Map<String, dynamic>;

      int pulledCount = 0;

      // 3. Apply Server Changes & Mark Local Synced inside SQLite Transaction
      await db.transaction((txn) async {
        // Mark all pushed records as synced = 1
        await txn.update('wallets', {'synced': 1});
        await txn.update('categories', {'synced': 1});
        await txn.update('transactions', {'synced': 1});
        await txn.update('wallet_transfers', {'synced': 1});
        await txn.update('monthly_budgets', {'synced': 1});
        await txn.update('category_monthly_budgets', {'synced': 1});
        await txn.update('saving_goals', {'synced': 1});
        await txn.update('saving_goal_logs', {'synced': 1});
        await txn.update('loan_contacts', {'synced': 1});
        await txn.update('loan_transactions', {'synced': 1});
        await txn.update('recurring_configs', {'synced': 1});
        await txn.delete('pending_deletions');

        // Apply incoming deletions
        final deletions = changes['deletions'] as List<dynamic>? ?? [];
        for (final d in deletions) {
          final table = d['table_name'] as String;
          final id = d['id'] as String;
          await txn.delete(table, where: 'id = ?', whereArgs: [id]);
          pulledCount++;
        }

        // Apply incoming Wallets
        final wallets = changes['wallets'] as List<dynamic>? ?? [];
        for (final w in wallets) {
          await txn.insert('wallets', _parseWalletFromSync(w), conflictAlgorithm: ConflictAlgorithm.replace);
          pulledCount++;
        }

        // Apply incoming Categories
        final categories = changes['categories'] as List<dynamic>? ?? [];
        for (final c in categories) {
          await txn.insert('categories', _parseCategoryFromSync(c), conflictAlgorithm: ConflictAlgorithm.replace);
          pulledCount++;
        }

        // Apply incoming Transactions
        final transactions = changes['transactions'] as List<dynamic>? ?? [];
        for (final t in transactions) {
          await txn.insert('transactions', _parseTransactionFromSync(t), conflictAlgorithm: ConflictAlgorithm.replace);
          pulledCount++;
        }

        // Apply incoming Wallet Transfers
        final transfers = changes['wallet_transfers'] as List<dynamic>? ?? [];
        for (final wt in transfers) {
          await txn.insert('wallet_transfers', _parseTransferFromSync(wt), conflictAlgorithm: ConflictAlgorithm.replace);
          pulledCount++;
        }

        // Apply incoming Monthly Budgets
        final budgets = changes['monthly_budgets'] as List<dynamic>? ?? [];
        for (final mb in budgets) {
          await txn.insert('monthly_budgets', _parseBudgetFromSync(mb), conflictAlgorithm: ConflictAlgorithm.replace);
          pulledCount++;
        }

        // Apply incoming Category Monthly Budgets
        final catBudgets = changes['category_monthly_budgets'] as List<dynamic>? ?? [];
        for (final cmb in catBudgets) {
          await txn.insert('category_monthly_budgets', _parseCatBudgetFromSync(cmb), conflictAlgorithm: ConflictAlgorithm.replace);
          pulledCount++;
        }

        // Apply incoming Saving Goals
        final goals = changes['saving_goals'] as List<dynamic>? ?? [];
        for (final sg in goals) {
          await txn.insert('saving_goals', _parseGoalFromSync(sg), conflictAlgorithm: ConflictAlgorithm.replace);
          pulledCount++;
        }

        // Apply incoming Saving Goal Logs
        final goalLogs = changes['saving_goal_logs'] as List<dynamic>? ?? [];
        for (final sgl in goalLogs) {
          await txn.insert('saving_goal_logs', _parseGoalLogFromSync(sgl), conflictAlgorithm: ConflictAlgorithm.replace);
          pulledCount++;
        }

        // Apply incoming Loan Contacts
        final loans = changes['loan_contacts'] as List<dynamic>? ?? [];
        for (final lc in loans) {
          await txn.insert('loan_contacts', _parseLoanFromSync(lc), conflictAlgorithm: ConflictAlgorithm.replace);
          pulledCount++;
        }

        // Apply incoming Loan Transactions
        final loanTxs = changes['loan_transactions'] as List<dynamic>? ?? [];
        for (final lt in loanTxs) {
          await txn.insert('loan_transactions', _parseLoanTxFromSync(lt), conflictAlgorithm: ConflictAlgorithm.replace);
          pulledCount++;
        }

        // Apply incoming Recurring Configs
        final recurrings = changes['recurring_configs'] as List<dynamic>? ?? [];
        for (final rc in recurrings) {
          await txn.insert('recurring_configs', _parseRecurringFromSync(rc), conflictAlgorithm: ConflictAlgorithm.replace);
          pulledCount++;
        }

        // 4. Recalculate all wallet current_balances based on initial_balance + delta transactions
        await _recalculateWalletBalances(txn);
      });

      // 5. Update last_synced_server_time
      await prefs.setString('last_synced_server_time', serverTimeStr);

      return SyncResult(
        success: true,
        message: 'Sync completed successfully',
        pushedCount: pushedCount,
        pulledCount: pulledCount,
        serverTime: DateTime.parse(serverTimeStr),
      );
    } catch (e) {
      debugPrint('[SyncService] Sync error: $e');
      return SyncResult(success: false, message: 'Sync failed: $e');
    } finally {
      _isSyncing = false;
    }
  }

  /// Recalculates current_balance for all wallets using transaction deltas.
  Future<void> _recalculateWalletBalances(DatabaseExecutor db) async {
    final wallets = await db.query('wallets');
    for (final w in wallets) {
      final walletId = w['id'] as String;
      final initialBalance = (w['initial_balance'] as num?)?.toDouble() ?? 0.0;

      // Income sum
      final incomeRes = await db.rawQuery(
        "SELECT SUM(amount) as total FROM transactions WHERE wallet_id = ? AND type = 'income'",
        [walletId],
      );
      final totalIncome = (incomeRes.first['total'] as num?)?.toDouble() ?? 0.0;

      // Expense sum
      final expenseRes = await db.rawQuery(
        "SELECT SUM(amount) as total FROM transactions WHERE wallet_id = ? AND type = 'expense'",
        [walletId],
      );
      final totalExpense = (expenseRes.first['total'] as num?)?.toDouble() ?? 0.0;

      // Transfer IN sum
      final transferInRes = await db.rawQuery(
        "SELECT SUM(amount) as total FROM wallet_transfers WHERE destination_wallet_id = ?",
        [walletId],
      );
      final totalTransferIn = (transferInRes.first['total'] as num?)?.toDouble() ?? 0.0;

      // Transfer OUT sum (amount + fee)
      final transferOutRes = await db.rawQuery(
        "SELECT SUM(amount + fee) as total FROM wallet_transfers WHERE source_wallet_id = ?",
        [walletId],
      );
      final totalTransferOut = (transferOutRes.first['total'] as num?)?.toDouble() ?? 0.0;

      final calculatedBalance = initialBalance + totalIncome - totalExpense + totalTransferIn - totalTransferOut;

      await db.update(
        'wallets',
        {'current_balance': calculatedBalance},
        where: 'id = ?',
        whereArgs: [walletId],
      );
    }
  }

  // Helper formatting methods for outgoing payloads
  String? _formatIsoUtc(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    if (str.isEmpty) return null;
    try {
      return DateTime.parse(str).toUtc().toIso8601String();
    } catch (_) {
      return str;
    }
  }

  String _formatIsoUtcRequired(dynamic val) {
    if (val == null) return DateTime.now().toUtc().toIso8601String();
    final str = val.toString().trim();
    if (str.isEmpty) return DateTime.now().toUtc().toIso8601String();
    try {
      return DateTime.parse(str).toUtc().toIso8601String();
    } catch (_) {
      return DateTime.now().toUtc().toIso8601String();
    }
  }

  String? _formatDateOnly(dynamic val) {
    if (val == null) return null;
    final str = val.toString().trim();
    if (str.isEmpty) return null;
    if (str.length >= 10 && RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(str)) {
      return str.substring(0, 10);
    }
    try {
      final dt = DateTime.parse(str);
      return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return str;
    }
  }

  String _formatDateOnlyRequired(dynamic val) {
    final res = _formatDateOnly(val);
    if (res != null) return res;
    final dt = DateTime.now();
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> _formatWalletForSync(Map<String, dynamic> w) => {
        'id': w['id'],
        'name': w['name'],
        'type': w['type'],
        'initial_balance': (w['initial_balance'] as num?)?.toDouble() ?? 0.0,
        'color': w['color'],
        'icon': w['icon'],
        'currency': w['currency'],
        'is_default': (w['is_default'] == 1 || w['is_default'] == true),
        'exclude_from_total': (w['exclude_from_total'] == 1 || w['exclude_from_total'] == true),
        'priority': w['priority'] ?? 0,
        'created_at': _formatIsoUtcRequired(w['created_at']),
        'updated_at': _formatIsoUtcRequired(w['updated_at']),
      };

  Map<String, dynamic> _formatCategoryForSync(Map<String, dynamic> c) => {
        'id': c['id'],
        'name': c['name'],
        'type': c['type'],
        'icon': c['icon'],
        'color': c['color'],
        'budget_limit': (c['budget_limit'] as num?)?.toDouble(),
        'created_at': _formatIsoUtcRequired(c['created_at']),
        'updated_at': _formatIsoUtcRequired(c['updated_at']),
      };

  Map<String, dynamic> _formatTransactionForSync(Map<String, dynamic> t) => {
        'id': t['id'],
        'wallet_id': t['wallet_id'],
        'category_id': t['category_id'],
        'recurring_config_id': t['recurring_config_id'],
        'amount': (t['amount'] as num?)?.toDouble() ?? 0.0,
        'formula': t['formula'],
        'note': t['note'],
        'type': t['type'],
        'transaction_date': _formatDateOnlyRequired(t['transaction_date']),
        'created_at': _formatIsoUtcRequired(t['created_at']),
        'updated_at': _formatIsoUtcRequired(t['updated_at']),
      };

  Map<String, dynamic> _formatTransferForSync(Map<String, dynamic> wt) => {
        'id': wt['id'],
        'source_wallet_id': wt['source_wallet_id'],
        'destination_wallet_id': wt['destination_wallet_id'],
        'amount': (wt['amount'] as num?)?.toDouble() ?? 0.0,
        'fee': (wt['fee'] as num?)?.toDouble() ?? 0.0,
        'transfer_date': _formatIsoUtcRequired(wt['transfer_date']),
        'note': wt['note'],
        'created_at': _formatIsoUtcRequired(wt['created_at']),
        'updated_at': _formatIsoUtcRequired(wt['updated_at']),
      };

  Map<String, dynamic> _formatBudgetForSync(Map<String, dynamic> mb) => {
        'id': mb['id'],
        'year': mb['year'],
        'month': mb['month'],
        'amount': (mb['amount'] as num?)?.toDouble() ?? 0.0,
        'created_at': _formatIsoUtcRequired(mb['created_at']),
        'updated_at': _formatIsoUtcRequired(mb['updated_at']),
      };

  Map<String, dynamic> _formatCatBudgetForSync(Map<String, dynamic> cmb) => {
        'id': cmb['id'],
        'category_id': cmb['category_id'],
        'year': cmb['year'],
        'month': cmb['month'],
        'amount': (cmb['amount'] as num?)?.toDouble() ?? 0.0,
        'created_at': _formatIsoUtcRequired(cmb['created_at']),
        'updated_at': _formatIsoUtcRequired(cmb['updated_at']),
      };

  Map<String, dynamic> _formatGoalForSync(Map<String, dynamic> sg) => {
        'id': sg['id'],
        'name': sg['name'],
        'target_amount': (sg['target_amount'] as num?)?.toDouble() ?? 0.0,
        'current_amount': (sg['current_amount'] as num?)?.toDouble() ?? 0.0,
        'target_date': _formatDateOnly(sg['target_date']),
        'color': sg['color'],
        'icon': sg['icon'],
        'note': sg['note'],
        'status': sg['status'] ?? 'active',
        'created_at': _formatIsoUtcRequired(sg['created_at']),
        'updated_at': _formatIsoUtcRequired(sg['updated_at']),
      };

  Map<String, dynamic> _formatGoalLogForSync(Map<String, dynamic> sgl) => {
        'id': sgl['id'],
        'goal_id': sgl['goal_id'],
        'amount': (sgl['amount'] as num?)?.toDouble() ?? 0.0,
        'type': sgl['type'],
        'log_date': _formatIsoUtcRequired(sgl['log_date']),
        'note': sgl['note'],
        'created_at': _formatIsoUtcRequired(sgl['created_at']),
        'updated_at': _formatIsoUtcRequired(sgl['updated_at']),
      };

  Map<String, dynamic> _formatLoanForSync(Map<String, dynamic> lc) => {
        'id': lc['id'],
        'contact_name': lc['contact_name'],
        'type': lc['type'],
        'total_amount': (lc['total_amount'] as num?)?.toDouble() ?? 0.0,
        'remaining_amount': (lc['remaining_amount'] as num?)?.toDouble() ?? 0.0,
        'status': lc['status'] ?? 'active',
        'created_at': _formatIsoUtcRequired(lc['created_at']),
        'updated_at': _formatIsoUtcRequired(lc['updated_at']),
      };

  Map<String, dynamic> _formatLoanTxForSync(Map<String, dynamic> lt) => {
        'id': lt['id'],
        'loan_id': lt['loan_id'],
        'amount': (lt['amount'] as num?)?.toDouble() ?? 0.0,
        'type': lt['type'],
        'date': _formatIsoUtcRequired(lt['date']),
        'due_date': _formatDateOnly(lt['due_date']),
        'note': lt['note'],
        'created_at': _formatIsoUtcRequired(lt['created_at']),
        'updated_at': _formatIsoUtcRequired(lt['updated_at']),
      };

  Map<String, dynamic> _formatRecurringForSync(Map<String, dynamic> rc) => {
        'id': rc['id'],
        'category_id': rc['category_id'],
        'wallet_id': rc['wallet_id'],
        'name': rc['name'],
        'amount': (rc['amount'] as num?)?.toDouble() ?? 0.0,
        'type': rc['type'],
        'frequency': rc['frequency'],
        'interval': rc['interval'] ?? 1,
        'day_of_week': rc['day_of_week'],
        'day_of_month': rc['day_of_month'],
        'next_run': _formatIsoUtcRequired(rc['next_run']),
        'is_active': (rc['is_active'] == 1 || rc['is_active'] == true),
        'created_at': _formatIsoUtcRequired(rc['created_at']),
        'updated_at': _formatIsoUtcRequired(rc['updated_at']),
      };

  // Helper parsing methods for incoming payloads
  Map<String, dynamic> _parseWalletFromSync(dynamic w) => {
        'id': w['id'],
        'name': w['name'],
        'type': w['type'],
        'initial_balance': (w['initial_balance'] as num).toDouble(),
        'current_balance': (w['initial_balance'] as num).toDouble(), // Will be recalculated
        'color': w['color'] ?? '#10B981',
        'icon': w['icon'] ?? 'wallet',
        'currency': w['currency'],
        'is_default': (w['is_default'] == true) ? 1 : 0,
        'exclude_from_total': (w['exclude_from_total'] == true) ? 1 : 0,
        'priority': w['priority'] ?? 0,
        'synced': 1,
        'created_at': w['created_at'],
        'updated_at': w['updated_at'],
      };

  Map<String, dynamic> _parseCategoryFromSync(dynamic c) => {
        'id': c['id'],
        'name': c['name'],
        'type': c['type'],
        'icon': c['icon'],
        'color': c['color'],
        'budget_limit': (c['budget_limit'] as num?)?.toDouble(),
        'synced': 1,
        'created_at': c['created_at'],
        'updated_at': c['updated_at'],
      };

  Map<String, dynamic> _parseTransactionFromSync(dynamic t) => {
        'id': t['id'],
        'wallet_id': t['wallet_id'],
        'category_id': t['category_id'],
        'recurring_config_id': t['recurring_config_id'],
        'amount': (t['amount'] as num).toDouble(),
        'formula': t['formula'],
        'note': t['note'],
        'type': t['type'],
        'transaction_date': t['transaction_date'],
        'synced': 1,
        'created_at': t['created_at'],
        'updated_at': t['updated_at'],
      };

  Map<String, dynamic> _parseTransferFromSync(dynamic wt) => {
        'id': wt['id'],
        'source_wallet_id': wt['source_wallet_id'],
        'destination_wallet_id': wt['destination_wallet_id'],
        'amount': (wt['amount'] as num).toDouble(),
        'fee': (wt['fee'] as num?)?.toDouble() ?? 0.0,
        'transfer_date': wt['transfer_date'],
        'note': wt['note'],
        'synced': 1,
        'created_at': wt['created_at'],
      };

  Map<String, dynamic> _parseBudgetFromSync(dynamic mb) => {
        'id': mb['id'],
        'year': mb['year'],
        'month': mb['month'],
        'amount': (mb['amount'] as num).toDouble(),
        'synced': 1,
        'created_at': mb['created_at'],
        'updated_at': mb['updated_at'],
      };

  Map<String, dynamic> _parseCatBudgetFromSync(dynamic cmb) => {
        'id': cmb['id'],
        'category_id': cmb['category_id'],
        'year': cmb['year'],
        'month': cmb['month'],
        'amount': (cmb['amount'] as num).toDouble(),
        'synced': 1,
        'created_at': cmb['created_at'],
        'updated_at': cmb['updated_at'],
      };

  Map<String, dynamic> _parseGoalFromSync(dynamic sg) => {
        'id': sg['id'],
        'name': sg['name'],
        'target_amount': (sg['target_amount'] as num).toDouble(),
        'current_amount': (sg['current_amount'] as num?)?.toDouble() ?? 0.0,
        'target_date': sg['target_date'],
        'color': sg['color'],
        'icon': sg['icon'],
        'note': sg['note'],
        'status': sg['status'] ?? 'active',
        'synced': 1,
        'created_at': sg['created_at'],
        'updated_at': sg['updated_at'],
      };

  Map<String, dynamic> _parseGoalLogFromSync(dynamic sgl) => {
        'id': sgl['id'],
        'goal_id': sgl['goal_id'],
        'amount': (sgl['amount'] as num).toDouble(),
        'type': sgl['type'],
        'log_date': sgl['log_date'],
        'note': sgl['note'],
        'synced': 1,
        'created_at': sgl['created_at'],
      };

  Map<String, dynamic> _parseLoanFromSync(dynamic lc) => {
        'id': lc['id'],
        'contact_name': lc['contact_name'],
        'type': lc['type'],
        'total_amount': (lc['total_amount'] as num).toDouble(),
        'remaining_amount': (lc['remaining_amount'] as num).toDouble(),
        'status': lc['status'] ?? 'active',
        'synced': 1,
        'created_at': lc['created_at'],
        'updated_at': lc['updated_at'],
      };

  Map<String, dynamic> _parseLoanTxFromSync(dynamic lt) => {
        'id': lt['id'],
        'loan_id': lt['loan_id'],
        'amount': (lt['amount'] as num).toDouble(),
        'type': lt['type'],
        'date': lt['date'],
        'due_date': lt['due_date'],
        'note': lt['note'],
        'synced': 1,
        'created_at': lt['created_at'],
        'updated_at': lt['updated_at'],
      };

  Map<String, dynamic> _parseRecurringFromSync(dynamic rc) => {
        'id': rc['id'],
        'category_id': rc['category_id'],
        'wallet_id': rc['wallet_id'],
        'name': rc['name'],
        'amount': (rc['amount'] as num).toDouble(),
        'type': rc['type'],
        'frequency': rc['frequency'],
        'interval': rc['interval'] ?? 1,
        'day_of_week': rc['day_of_week'],
        'day_of_month': rc['day_of_month'],
        'next_run': rc['next_run'],
        'is_active': (rc['is_active'] == true || rc['is_active'] == 1) ? 1 : 0,
        'synced': 1,
        'created_at': rc['created_at'],
        'updated_at': rc['updated_at'],
      };
}
