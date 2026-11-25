/// Represents a recurring financial transaction schedule stored in SQLite.
class RecurringConfig {
  final String id;
  final String? categoryId;
  final String? walletId;
  final String name;
  final double amount;
  final String type;
  final String frequency;
  final int interval;
  final int? dayOfWeek;

  /// Optional list of ISO weekdays (1=Monday .. 7=Sunday) on which this recurrence applies.
  /// When null or empty for daily recurrences, every day applies.
  final List<int>? daysOfWeek;
  final int? dayOfMonth;
  final DateTime nextRun;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Canonical weekday preset (Monday through Friday).
  static const List<int> weekdaysPreset = [1, 2, 3, 4, 5];

  /// Canonical weekend preset (Saturday and Sunday).
  static const List<int> weekendsPreset = [6, 7];

  /// Canonical all-days list (Monday through Sunday).
  static const List<int> allDaysPreset = [1, 2, 3, 4, 5, 6, 7];

  RecurringConfig({
    required this.id,
    this.categoryId,
    this.walletId,
    required this.name,
    required this.amount,
    required this.type,
    required this.frequency,
    required this.interval,
    this.dayOfWeek,
    List<int>? daysOfWeek,
    this.dayOfMonth,
    required this.nextRun,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  }) : daysOfWeek = normalizeDaysOfWeek(daysOfWeek);

  /// Normalizes a list of ISO weekday numbers (1=Mon..7=Sun) to sorted, deduplicated values.
  ///
  /// @param days Raw list of weekday integers.
  /// @returns Sorted unique list of 1..7 integers, or null if empty.
  static List<int>? normalizeDaysOfWeek(List<int>? days) {
    if (days == null || days.isEmpty) return null;
    final filtered = days.where((d) => d >= 1 && d <= 7).toSet().toList()..sort();
    return filtered.isEmpty ? null : filtered;
  }

  /// Converts a legacy 0-indexed dayOfWeek (0=Sun, 1=Mon..6=Sat) into ISO weekday (1=Mon..7=Sun).
  ///
  /// @param dayOfWeek Legacy day of week integer.
  /// @returns ISO weekday integer in range 1..7.
  static int legacyDayOfWeekToIso(int dayOfWeek) {
    final mod = dayOfWeek % 7;
    return mod == 0 ? 7 : mod;
  }

  /// Encodes ISO weekday numbers into a canonical comma-separated string for SQLite storage.
  ///
  /// @param days List of ISO weekdays.
  /// @returns Canonical CSV string such as "1,2,3,4,5", or null if empty.
  static String? encodeDaysOfWeek(List<int>? days) {
    final normalized = normalizeDaysOfWeek(days);
    if (normalized == null) return null;
    return normalized.join(',');
  }

  /// Decodes a CSV string or JSON array of ISO weekday numbers into a normalized list.
  ///
  /// @param raw Stored CSV string, JSON List, or null.
  /// @returns Normalized ISO weekday list (1..7), or null if empty.
  static List<int>? decodeDaysOfWeek(dynamic raw) {
    if (raw == null) return null;
    if (raw is List) {
      final parsed = <int>[];
      for (final item in raw) {
        if (item is int) {
          parsed.add(item);
        } else if (item is num) {
          parsed.add(item.toInt());
        } else if (item is String) {
          final v = int.tryParse(item.trim());
          if (v != null) parsed.add(v);
        }
      }
      return normalizeDaysOfWeek(parsed);
    }
    if (raw is String) {
      final trimmed = raw.trim();
      if (trimmed.isEmpty) return null;
      final parsed = trimmed
          .split(',')
          .map((part) => int.tryParse(part.trim()))
          .whereType<int>()
          .toList();
      return normalizeDaysOfWeek(parsed);
    }
    return null;
  }

  /// Returns the effective list of ISO weekdays (1..7) for scheduling, falling back to legacy [dayOfWeek]
  /// for weekly schedules that have not yet populated [daysOfWeek].
  List<int>? get effectiveDaysOfWeek {
    if (daysOfWeek != null && daysOfWeek!.isNotEmpty) {
      return daysOfWeek;
    }
    if (frequency == 'weekly' && dayOfWeek != null) {
      return [legacyDayOfWeekToIso(dayOfWeek!)];
    }
    return null;
  }

  /// Returns a copy of this configuration with the provided fields replaced.
  RecurringConfig copyWith({
    String? id,
    String? categoryId,
    bool clearCategoryId = false,
    String? walletId,
    bool clearWalletId = false,
    String? name,
    double? amount,
    String? type,
    String? frequency,
    int? interval,
    int? dayOfWeek,
    bool clearDayOfWeek = false,
    List<int>? daysOfWeek,
    bool clearDaysOfWeek = false,
    int? dayOfMonth,
    bool clearDayOfMonth = false,
    DateTime? nextRun,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return RecurringConfig(
      id: id ?? this.id,
      categoryId: clearCategoryId ? null : (categoryId ?? this.categoryId),
      walletId: clearWalletId ? null : (walletId ?? this.walletId),
      name: name ?? this.name,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      frequency: frequency ?? this.frequency,
      interval: interval ?? this.interval,
      dayOfWeek: clearDayOfWeek ? null : (dayOfWeek ?? this.dayOfWeek),
      daysOfWeek: clearDaysOfWeek ? null : (daysOfWeek ?? this.daysOfWeek),
      dayOfMonth: clearDayOfMonth ? null : (dayOfMonth ?? this.dayOfMonth),
      nextRun: nextRun ?? this.nextRun,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Serializes this configuration into a SQLite column map.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'category_id': categoryId,
      'wallet_id': walletId,
      'name': name,
      'amount': amount,
      'type': type,
      'frequency': frequency,
      'interval': interval,
      'day_of_week': dayOfWeek,
      'days_of_week': encodeDaysOfWeek(daysOfWeek),
      'day_of_month': dayOfMonth,
      'next_run': nextRun.toIso8601String(),
      'is_active': isActive ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Deserializes a SQLite row map into a [RecurringConfig], normalizing [nextRun] to local time.
  factory RecurringConfig.fromMap(Map<String, dynamic> map) {
    return RecurringConfig(
      id: map['id'] as String,
      categoryId: map['category_id'] as String?,
      walletId: map['wallet_id'] as String?,
      name: map['name'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      frequency: map['frequency'] as String,
      interval: map['interval'] as int,
      dayOfWeek: map['day_of_week'] as int?,
      daysOfWeek: decodeDaysOfWeek(map['days_of_week']),
      dayOfMonth: map['day_of_month'] as int?,
      nextRun: DateTime.parse(map['next_run'] as String).toLocal(),
      isActive: (map['is_active'] as int) == 1,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(map['updated_at'] as String).toLocal(),
    );
  }
}
