import 'package:uuid/uuid.dart';

class SavingGoalLog {
  final String id;
  final String goalId;
  final double amount;
  final String type; // 'deposit' or 'withdraw'
  final DateTime logDate;
  final String? note;
  final DateTime createdAt;

  SavingGoalLog({
    String? id,
    required this.goalId,
    required this.amount,
    required this.type,
    required this.logDate,
    this.note,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  bool get isDeposit => type == 'deposit';
  bool get isWithdraw => type == 'withdraw';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'goal_id': goalId,
      'amount': amount,
      'type': type,
      'log_date': logDate.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory SavingGoalLog.fromMap(Map<String, dynamic> map) {
    return SavingGoalLog(
      id: map['id'] as String,
      goalId: map['goal_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      logDate: DateTime.tryParse(map['log_date'] as String? ?? '') ??
          DateTime.now(),
      note: map['note'] as String?,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
