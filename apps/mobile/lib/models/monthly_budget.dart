class MonthlyBudget {
  final String id;
  final int year;
  final int month;
  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  MonthlyBudget({
    required this.id,
    required this.year,
    required this.month,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  MonthlyBudget copyWith({
    String? id,
    int? year,
    int? month,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return MonthlyBudget(
      id: id ?? this.id,
      year: year ?? this.year,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'year': year,
      'month': month,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory MonthlyBudget.fromMap(Map<String, dynamic> map) {
    return MonthlyBudget(
      id: map['id'] as String,
      year: map['year'] as int,
      month: map['month'] as int,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class CategoryMonthlyBudget {
  final String id;
  final String categoryId;
  final int year;
  final int month;
  final double amount;
  final DateTime createdAt;
  final DateTime updatedAt;

  CategoryMonthlyBudget({
    required this.id,
    required this.categoryId,
    required this.year,
    required this.month,
    required this.amount,
    required this.createdAt,
    required this.updatedAt,
  });

  CategoryMonthlyBudget copyWith({
    String? id,
    String? categoryId,
    int? year,
    int? month,
    double? amount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CategoryMonthlyBudget(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      year: year ?? this.year,
      month: month ?? this.month,
      amount: amount ?? this.amount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'year': year,
      'month': month,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory CategoryMonthlyBudget.fromMap(Map<String, dynamic> map) {
    return CategoryMonthlyBudget(
      id: map['id'] as String,
      categoryId: map['category_id'] as String,
      year: map['year'] as int,
      month: map['month'] as int,
      amount: (map['amount'] as num).toDouble(),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}

class CategoryBudgetStatus {
  final String categoryId;
  final double budgetLimit;
  final double spent;
  final double remaining;
  final double percentage; // 0.0 to >1.0

  const CategoryBudgetStatus({
    required this.categoryId,
    required this.budgetLimit,
    required this.spent,
    required this.remaining,
    required this.percentage,
  });

  bool get hasBudget => budgetLimit > 0;
  bool get isOverBudget => spent > budgetLimit && budgetLimit > 0;
  bool get isNearLimit => percentage >= 0.8 && percentage <= 1.0;
}

class MonthlyBudgetSummary {
  final int year;
  final int month;
  final double totalBudget;
  final double totalSpent;
  final double remaining;
  final double percentageUsed;
  final Map<String, CategoryBudgetStatus> categoryStatuses;

  const MonthlyBudgetSummary({
    required this.year,
    required this.month,
    required this.totalBudget,
    required this.totalSpent,
    required this.remaining,
    required this.percentageUsed,
    required this.categoryStatuses,
  });

  bool get hasBudget => totalBudget > 0;
  bool get isOverBudget => totalSpent > totalBudget && totalBudget > 0;
}
