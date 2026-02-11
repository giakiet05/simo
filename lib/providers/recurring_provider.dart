import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/recurring_config.dart';
import '../repositories/recurring_repository.dart';

class RecurringNotifier extends StateNotifier<AsyncValue<List<RecurringConfig>>> {
  final RecurringRepository _repository = RecurringRepository();

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
    required String name,
    required double amount,
    required String type,
    required String frequency,
    required int interval,
    int? dayOfWeek,
    int? dayOfMonth,
  }) async {
    try {
      await _repository.create(
        categoryId: categoryId,
        name: name,
        amount: amount,
        type: type,
        frequency: frequency,
        interval: interval,
        dayOfWeek: dayOfWeek,
        dayOfMonth: dayOfMonth,
      );
      await loadRecurringConfigs();
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateRecurringConfig(
    String id, {
    String? categoryId,
    String? name,
    double? amount,
    String? type,
    String? frequency,
    int? interval,
    int? dayOfWeek,
    int? dayOfMonth,
    bool? isActive,
  }) async {
    try {
      await _repository.update(
        id,
        categoryId: categoryId,
        name: name,
        amount: amount,
        type: type,
        frequency: frequency,
        interval: interval,
        dayOfWeek: dayOfWeek,
        dayOfMonth: dayOfMonth,
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
}

final recurringProvider = StateNotifierProvider<RecurringNotifier, AsyncValue<List<RecurringConfig>>>((ref) {
  return RecurringNotifier();
});
