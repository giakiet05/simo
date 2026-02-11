class RecurringConfig {
  final String id;
  final String? categoryId;
  final String name;
  final double amount;
  final String type;
  final String frequency;
  final int interval;
  final int? dayOfWeek;
  final int? dayOfMonth;
  final DateTime nextRun;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  RecurringConfig({
    required this.id,
    this.categoryId,
    required this.name,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.interval,
    this.dayOfWeek,
    this.dayOfMonth,
    required this.nextRun,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  RecurringConfig copyWith({
    String? id,
    String? categoryId,
    String? name,
    double? amount,
    String? type,
    String? frequency,
    int? interval,
    int? dayOfWeek,
    int? dayOfMonth,
    DateTime? nextRun,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringConfig(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      nextRun: nextRun ?? this.nextRun,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'name': name,
      'amount': amount,
      'type': type,
      'frequency': frequency,
      'interval': interval,
      'day_of_week': dayOfWeek,
      'day_of_month': dayOfMonth,
      'next_run': nextRun.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory RecurringConfig.fromMap(Map<String, dynamic> map) {
    return RecurringConfig(
      id: map['id'] as String,
      categoryId: map['category_id'] as String?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      frequency: map['frequency'] as String,
      interval: map['interval'] as int,
      dayOfWeek: map['day_of_week'] as int?,
      dayOfMonth: map['day_of_month'] as int?,
      nextRun: DateTime.parse(map['next_run'] as String),
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
