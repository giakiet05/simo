import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recurring_config.dart';
import '../repositories/recurring_repository.dart';
import '../repositories/transaction_repository.dart';
import '../utils/recurring_service.dart';
import 'monthly_budget_provider.dart';
import 'sync_provider.dart';
import 'transaction_provider.dart';
import 'wallet_provider.dart';

/// Manages recurring transaction configurations, manual triggers, and automated due execution.
class RecurringNotifier extends StateNotifier<AsyncValue<List<RecurringConfig>>> {
  final Ref _ref;
  final RecurringRepository _repository = RecurringRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();
  final RecurringService _recurringService = RecurringService();

  RecurringNotifier(this._ref) : super(const AsyncValue.loading()) {
    loadRecurringConfigs();
  }

  /// Loads all recurring configurations from local SQLite.
  Future<void> loadRecurringConfigs({bool? isActive}) async {
    state = const AsyncValue.loading();
    try {
      final configs = await _repository.getAll(isActive: isActive);
      state = AsyncValue.data(configs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Creates a new recurring configuration and schedules a debounced cloud sync.
  Future<void> createRecurringConfig({
    required String? categoryId,
    String? walletId,
    required String name,
    required double amount,
    required String type,
    required String frequency,
    required int interval,
    int? dayOfWeek,
    List<int>? daysOfWeek,
    int? dayOfMonth,
    DateTime? nextRun,
  }) async {
    try {
      await _repository.create(
        categoryId: categoryId,
        walletId: walletId,
        name: name,
        amount: amount,
        type: type,
        frequency: frequency,
        interval: interval,
        dayOfWeek: dayOfWeek,
        daysOfWeek: daysOfWeek,
        dayOfMonth: dayOfMonth,
        nextRun: nextRun,
      );
      await loadRecurringConfigs();
      _triggerSyncSafely();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Updates an existing recurring configuration and schedules a debounced cloud sync.
  Future<void> updateRecurringConfig(
    String id, {
    String? categoryId,
    bool clearCategory = false,
    String? walletId,
    bool clearWallet = false,
    String? name,
    double? amount,
    String? type,
    String? frequency,
    int? interval,
    int? dayOfWeek,
    bool clearDayOfWeek = false,
    List<int>? daysOfWeek,
    bool clearDaysOfWeek = false,
    int? dayOfMonth,
    bool clearDayOfMonth = false,
    DateTime? nextRun,
    bool? isActive,
  }) async {
    try {
      await _repository.update(
        id,
        categoryId: categoryId,
        clearCategory: clearCategory,
        walletId: walletId,
        clearWallet: clearWallet,
        name: name,
        amount: amount,
        type: type,
        frequency: frequency,
        interval: interval,
        dayOfWeek: dayOfWeek,
        clearDayOfWeek: clearDayOfWeek,
        daysOfWeek: daysOfWeek,
        clearDaysOfWeek: clearDaysOfWeek,
        dayOfMonth: dayOfMonth,
        clearDayOfMonth: clearDayOfMonth,
        nextRun: nextRun,
        isActive: isActive,
      );
      await loadRecurringConfigs();
      _triggerSyncSafely();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Deletes a recurring configuration and schedules a debounced cloud sync.
  Future<void> deleteRecurringConfig(String id) async {
    try {
      await _repository.delete(id);
      await loadRecurringConfigs();
      _triggerSyncSafely();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Toggles the active state of a recurring configuration and triggers cloud sync.
  Future<void> toggleActive(String id, bool isActive) async {
    try {
      await _repository.update(id, isActive: isActive);
      await loadRecurringConfigs();
      _triggerSyncSafely();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Immediately generates one transaction from a recurring configuration and refreshes dependent providers.
  Future<void> triggerRecurringNow(String id) async {
    try {
      final configs = await _repository.getAll();
      final config = configs.firstWhere((c) => c.id == id);

      await _transactionRepository.createMultiple([
        {
          'categoryId': config.categoryId,
          'walletId': config.walletId,
          'amount': config.amount,
          'type': config.type,
          'recurringConfigId': id,
          'formula': null,
          'note': config.name,
        }
      ]);

      _invalidateFinancialProviders();
      _triggerSyncSafely();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }

  /// Runs automated due recurring processing (catch-up across missed days), refreshing
  /// transactions, wallets, budgets, and scheduling cloud sync if any transactions were generated.
  ///
  /// @returns Number of auto-generated transactions created.
  Future<int> processDueRecurring() async {
    final generated = await _recurringService.processRecurringTransactions();
    if (generated > 0) {
      await loadRecurringConfigs();
      _invalidateFinancialProviders();
      _triggerSyncSafely();
    }
    return generated;
  }

  void _invalidateFinancialProviders() {
    _ref.invalidate(transactionProvider);
    _ref.invalidate(walletProvider);
    _ref.invalidate(monthlyBudgetFamily);
  }

  void _triggerSyncSafely() {
    try {
      _ref.read(syncProvider.notifier).triggerDebouncedSync();
    } catch (_) {
      // Sync provider may be uninitialized in isolated unit tests.
    }
  }
}

final recurringRepositoryProvider = Provider<RecurringRepository>((ref) {
  return RecurringRepository();
});

final recurringProvider = StateNotifierProvider<RecurringNotifier, AsyncValue<List<RecurringConfig>>>((ref) {
  return RecurringNotifier(ref);
});
