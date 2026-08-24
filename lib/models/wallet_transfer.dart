class WalletTransfer {
  final String id;
  final String sourceWalletId;
  final String destinationWalletId;
  final double amount;
  final double fee;
  final DateTime transferDate;
  final String? note;
  final DateTime createdAt;

  WalletTransfer({
    required this.id,
    required this.sourceWalletId,
    required this.destinationWalletId,
    required this.amount,
    this.fee = 0.0,
    required this.transferDate,
    this.note,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_wallet_id': sourceWalletId,
      'destination_wallet_id': destinationWalletId,
      'amount': amount,
      'fee': fee,
      'transfer_date': transferDate.toIso8601String(),
      'note': note,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory WalletTransfer.fromMap(Map<String, dynamic> map) {
    return WalletTransfer(
      id: map['id'] as String,
      sourceWalletId: map['source_wallet_id'] as String,
      destinationWalletId: map['destination_wallet_id'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      fee: (map['fee'] as num?)?.toDouble() ?? 0.0,
      transferDate: map['transfer_date'] != null
          ? DateTime.tryParse(map['transfer_date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      note: map['note'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  WalletTransfer copyWith({
    String? id,
    String? sourceWalletId,
    String? destinationWalletId,
    double? amount,
    double? fee,
    DateTime? transferDate,
    String? note,
    DateTime? createdAt,
  }) {
    return WalletTransfer(
      id: id ?? this.id,
      sourceWalletId: sourceWalletId ?? this.sourceWalletId,
      destinationWalletId: destinationWalletId ?? this.destinationWalletId,
      amount: amount ?? this.amount,
      fee: fee ?? this.fee,
      transferDate: transferDate ?? this.transferDate,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
