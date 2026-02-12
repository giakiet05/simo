class Category {
  final String id;
  final String name;
  final String type; // 'income' or 'expense'
  final String? icon;
  final String? color;
  final DateTime createdAt;
  final DateTime updatedAt;

  Category({
    required this.id,
    required this.name,
    required this.type,
    this.icon,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  Category copyWith({
    String? id,
    String? name,
    String? type,
    String? icon,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }
}
