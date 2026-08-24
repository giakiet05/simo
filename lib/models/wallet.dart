class Wallet {
  final String id;
  final String name;
  final String type; // 'cash', 'bank', 'ewallet', 'credit', 'savings', 'other'
  final double initialBalance;
  final double currentBalance;
  final String color;
  final String icon;
  final String? currency;
  final bool isDefault;
  final bool excludeFromTotal;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wallet({
    required this.id,
    required this.name,
    required this.type,
    this.initialBalance = 0.0,
    this.currentBalance = 0.0,
    required this.color,
    required this.icon,
    this.currency,
    this.isDefault = false,
    this.excludeFromTotal = false,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'initial_balance': initialBalance,
      'current_balance': currentBalance,
      'color': color,
      'icon': icon,
      'currency': currency,
      'is_default': isDefault ? 1 : 0,
      'exclude_from_total': excludeFromTotal ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Wallet.fromMap(Map<String, dynamic> map) {
    return Wallet(
      id: map['id'] as String,
      name: map['name'] as String,
      type: (map['type'] as String?) ?? 'cash',
      initialBalance: (map['initial_balance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (map['current_balance'] as num?)?.toDouble() ?? 0.0,
      color: (map['color'] as String?) ?? '#10B981',
      icon: (map['icon'] as String?) ?? 'wallet',
      currency: map['currency'] as String?,
      isDefault: (map['is_default'] as int?) == 1,
      excludeFromTotal: (map['exclude_from_total'] as int?) == 1,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Wallet copyWith({
    String? id,
    String? name,
    String? type,
    double? initialBalance,
    double? currentBalance,
    String? color,
    String? icon,
    String? currency,
    bool? isDefault,
    bool? excludeFromTotal,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      currency: currency ?? this.currency,
      isDefault: isDefault ?? this.isDefault,
      excludeFromTotal: excludeFromTotal ?? this.excludeFromTotal,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
