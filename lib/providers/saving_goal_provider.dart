import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/saving_goal.dart';
import '../models/saving_goal_log.dart';
import '../repositories/saving_goal_repository.dart';

final savingGoalRepositoryProvider = Provider<SavingGoalRepository>((ref) {
  return SavingGoalRepository();
});

class SavingGoalNotifier extends StateNotifier<AsyncValue<List<SavingGoal>>> {
  final SavingGoalRepository _repository;

  SavingGoalNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadGoals();
  }

  Future<void> loadGoals({String? status}) async {
    state = const AsyncValue.loading();
    try {
      final goals = await _repository.getAll(status: status);
      state = AsyncValue.data(goals);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> createGoal(SavingGoal goal) async {
    try {
      await _repository.create(goal);
      await loadGoals();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateGoal(SavingGoal goal) async {
    try {
      await _repository.update(goal);
      await loadGoals();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteGoal(String id) async {
    try {
      final success = await _repository.delete(id);
      if (success) {
        await loadGoals();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<bool> addLog({
    required String goalId,
    required double amount,
    required String type,
    required DateTime logDate,
    String? note,
  }) async {
    try {
      await _repository.addLog(
        goalId: goalId,
        amount: amount,
        type: type,
        logDate: logDate,
        note: note,
      );
      await loadGoals();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteLog(String logId) async {
    try {
      final success = await _repository.deleteLog(logId);
      if (success) {
        await loadGoals();
      }
      return success;
    } catch (e) {
      return false;
    }
  }

  Future<List<SavingGoalLog>> getLogs(String goalId) async {
    return await _repository.getLogs(goalId);
  }
}

final savingGoalProvider =
    StateNotifierProvider<SavingGoalNotifier, AsyncValue<List<SavingGoal>>>((ref) {
  final repo = ref.watch(savingGoalRepositoryProvider);
  return SavingGoalNotifier(repo);
});

final savingGoalLogsProvider =
    FutureProvider.family<List<SavingGoalLog>, String>((ref, goalId) async {
  final repo = ref.watch(savingGoalRepositoryProvider);
  return await repo.getLogs(goalId);
});
