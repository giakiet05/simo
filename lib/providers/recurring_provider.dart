import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recurring_config.dart';
import '../repositories/recurring_repository.dart';
import '../repositories/transaction_repository.dart';

class RecurringNotifier extends StateNotifier<AsyncValue<List<RecurringConfig>>> {
  final RecurringRepository _repository = RecurringRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();

  RecurringNotifier() : super(const AsyncValue.loading()) {
    loadRecurringConfigs();
  }

  Future<void> loadRecurringConfigs({bool? isActive}) async {
    state = const AsyncValue.loading();
    try {
      final configs = await _repository.getAll(isActive: isActive);
      state = AsyncValue.data(configs);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createRecurringConfig({
    required String? categoryId,
    String? walletId,
    required String name,
    required double amount,
    required String type,
    required String frequency,
    required int interval,
    int? dayOfWeek,
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
        dayOfMonth: dayOfMonth,
        nextRun: nextRun,
      );
      await loadRecurringConfigs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

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
    int? dayOfMonth,
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
        dayOfMonth: dayOfMonth,
        nextRun: nextRun,
        isActive: isActive,
      );
      await loadRecurringConfigs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> deleteRecurringConfig(String id) async {
    try {
      await _repository.delete(id);
      await loadRecurringConfigs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> toggleActive(String id, bool isActive) async {
    try {
      await _repository.update(id, isActive: isActive);
      await loadRecurringConfigs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> triggerRecurringNow(String id) async {
    try {
      // Get recurring config
      final configs = await _repository.getAll();
      final config = configs.firstWhere((c) => c.id == id);

      // Create transaction from recurring config
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
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
      rethrow;
    }
  }
}

final recurringProvider = StateNotifierProvider<RecurringNotifier, AsyncValue<List<RecurringConfig>>>((ref) {
  return RecurringNotifier();
});
