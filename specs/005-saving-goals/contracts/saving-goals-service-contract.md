# Service Contracts: Saving Goals (Mục tiêu tiết kiệm / Hũ tích lũy)

**Feature**: `005-saving-goals`

## 1. SavingGoalRepository Contract

```dart
abstract class ISavingGoalRepository {
  /// Fetches all saving goals, optionally filtered by status ('active', 'completed', 'paused')
  Future<List<SavingGoal>> getAll({String? status});

  /// Fetches a single goal by ID along with its details
  Future<SavingGoal?> getById(String id);

  /// Creates a new saving goal
  Future<SavingGoal> create(SavingGoal goal);

  /// Updates existing saving goal fields
  Future<SavingGoal> update(SavingGoal goal);

  /// Deletes a saving goal and cascades deletion of its logs
  Future<bool> delete(String id);

  /// Adds a deposit or withdrawal log and atomically updates current_amount
  Future<SavingGoalLog> addLog({
    required String goalId,
    required double amount,
    required String type, // 'deposit' or 'withdraw'
    required DateTime logDate,
    String? note,
  });

  /// Deletes a specific log and recalculates current_amount
  Future<bool> deleteLog(String logId);

  /// Fetches all logs for a given goal ordered by logDate DESC
  Future<List<SavingGoalLog>> getLogs(String goalId);
}
```

---

## 2. SavingGoalNotifier (Riverpod) Contract

```dart
class SavingGoalState {
  final List<SavingGoal> goals;
  final bool isLoading;
  final String? error;

  double get totalTargetAmount => goals.fold(0, (sum, g) => sum + g.targetAmount);
  double get totalSavedAmount => goals.fold(0, (sum, g) => sum + g.currentAmount);
  double get overallProgress => totalTargetAmount > 0 ? (totalSavedAmount / totalTargetAmount).clamp(0.0, 1.0) : 0.0;
}

abstract class ISavingGoalNotifier {
  Future<void> loadGoals({String? status});
  Future<bool> createGoal(SavingGoal goal);
  Future<bool> updateGoal(SavingGoal goal);
  Future<bool> deleteGoal(String id);
  Future<bool> depositOrWithdraw({
    required String goalId,
    required double amount,
    required String type,
    required DateTime logDate,
    String? note,
  });
}
```
