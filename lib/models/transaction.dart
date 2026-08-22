class Transaction {
  final String id;
  final String? categoryId;
  final String? recurringConfigId;
  final double amount;
  final String? formula;
  final String? note;
  final String type;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Transaction({
    required this.id,
    this.categoryId,
    this.recurringConfigId,
    required this.amount,
    this.formula,
    this.note,
    required this.type,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
  });

  Transaction copyWith({
    String? id,
    String? categoryId,
    String? recurringConfigId,
    double? amount,
    String? formula,
    String? note,
    String? type,
    DateTime? transactionDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Transaction(
      id: id ?? this.id,
      categoryId: categoryId ?? this.categoryId,
      recurringConfigId: recurringConfigId ?? this.recurringConfigId,
      amount: amount ?? this.amount,
      formula: formula ?? this.formula,
      note: note ?? this.note,
      type: type ?? this.type,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'recurring_config_id': recurringConfigId,
      'amount': amount,
      'formula': formula,
      'note': note,
      'type': type,
      'transaction_date': transactionDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    final createdAt = map['created_at'] != null
        ? DateTime.parse(map['created_at'] as String)
        : DateTime.now();
    return Transaction(
      id: map['id'] as String,
      categoryId: map['category_id'] as String?,
      recurringConfigId: map['recurring_config_id'] as String?,
      amount: (map['amount'] as num).toDouble(),
      formula: map['formula'] as String?,
      note: map['note'] as String?,
      type: map['type'] as String,
      transactionDate: map['transaction_date'] != null
          ? DateTime.parse(map['transaction_date'] as String)
          : createdAt,
      createdAt: createdAt,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : createdAt,
    );
  }
}
