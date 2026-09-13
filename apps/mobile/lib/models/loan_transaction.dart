import 'package:uuid/uuid.dart';

class LoanTransaction {
  final String id;
  final String? cloudId;
  final String loanId;
  final double amount;
  final String type; // 'borrow' (borrow more), 'repay' (repay borrowed money), 'lend' (lend more), 'collect' (collect lent money)
  final DateTime date;
  final DateTime? dueDate;
  final String note;
  final int synced;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoanTransaction({
    String? id,
    this.cloudId,
    required this.loanId,
    required this.amount,
    required this.type,
    required this.date,
    this.dueDate,
    this.note = '',
    this.synced = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cloud_id': cloudId,
      'loan_id': loanId,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
      'due_date': dueDate?.toIso8601String(),
      'note': note,
      'synced': synced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LoanTransaction.fromMap(Map<String, dynamic> map) {
    return LoanTransaction(
      id: map['id'],
      cloudId: map['cloud_id'],
      loanId: map['loan_id'],
      amount: map['amount'],
      type: map['type'],
      date: DateTime.parse(map['date']),
      dueDate: map['due_date'] != null ? DateTime.parse(map['due_date']) : null,
      note: map['note'] ?? '',
      synced: map['synced'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  LoanTransaction copyWith({
    String? id,
    String? cloudId,
    String? loanId,
    double? amount,
    String? type,
    DateTime? date,
    DateTime? dueDate,
    String? note,
    int? synced,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return LoanTransaction(
      id: id ?? this.id,
      cloudId: cloudId ?? this.cloudId,
      loanId: loanId ?? this.loanId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      date: date ?? this.date,
      dueDate: dueDate ?? this.dueDate,
      note: note ?? this.note,
      synced: synced ?? this.synced,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

