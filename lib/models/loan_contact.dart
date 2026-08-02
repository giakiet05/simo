import 'package:uuid/uuid.dart';

class LoanContact {
  final String id;
  final String? cloudId;
  final String contactName;
  final String type; // 'borrowed' (I borrowed money), 'lent' (I lent money)
  final double totalAmount;
  final double remainingAmount;
  final String status; // 'active', 'settled'
  final int synced;
  final DateTime createdAt;
  final DateTime updatedAt;

  LoanContact({
    String? id,
    this.cloudId,
    required this.contactName,
    required this.type,
    required this.totalAmount,
    required this.remainingAmount,
    this.status = 'active',
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
      'contact_name': contactName,
      'type': type,
      'total_amount': totalAmount,
      'remaining_amount': remainingAmount,
      'status': status,
      'synced': synced,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory LoanContact.fromMap(Map<String, dynamic> map) {
    return LoanContact(
      id: map['id'],
      cloudId: map['cloud_id'],
      contactName: map['contact_name'],
      type: map['type'],
      totalAmount: map['total_amount'],
      remainingAmount: map['remaining_amount'],
      status: map['status'] ?? 'active',
      synced: map['synced'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
    );
  }

  LoanContact copyWith({
    String? contactName,
    String? type,
    double? totalAmount,
    double? remainingAmount,
    String? status,
    int? synced,
    String? cloudId,
  }) {
    return LoanContact(
      id: id,
      cloudId: cloudId ?? this.cloudId,
      contactName: contactName ?? this.contactName,
      type: type ?? this.type,
      totalAmount: totalAmount ?? this.totalAmount,
      remainingAmount: remainingAmount ?? this.remainingAmount,
      status: status ?? this.status,
      synced: synced ?? this.synced,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
