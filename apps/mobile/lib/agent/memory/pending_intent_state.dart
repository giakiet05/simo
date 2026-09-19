/// Represents a pending user action that requires additional information (clarification)
/// before it can be safely executed by the agent.
class PendingIntent {
  /// The target tool or action name (e.g., 'loan_create', 'wallet_transfer', 'goal_create').
  final String actionType;

  /// Parameters and values already extracted from previous conversational turns.
  final Map<String, dynamic> extractedSlots;

  /// Mandatory parameters still required to fulfill the action.
  final List<String> missingFields;

  /// The clarifying question asked to the user.
  final String clarificationQuestion;

  /// Timestamp when the clarification was initiated.
  final DateTime createdAt;

  /// Time-to-live duration before a pending intent expires (default: 5 minutes).
  static const Duration defaultTtl = Duration(minutes: 5);

  const PendingIntent({
    required this.actionType,
    required this.extractedSlots,
    required this.missingFields,
    required this.clarificationQuestion,
    required this.createdAt,
  });

  /// Checks if the pending intent has exceeded its time-to-live threshold.
  bool isExpired({DateTime? now, Duration ttl = defaultTtl}) {
    final current = now ?? DateTime.now();
    return current.difference(createdAt) > ttl;
  }

  /// Merges newly provided slots into existing extracted slots and computes remaining missing fields.
  PendingIntent mergeSlots(Map<String, dynamic> newSlots) {
    final merged = Map<String, dynamic>.from(extractedSlots)..addAll(newSlots);
    final remaining = missingFields.where((field) => !merged.containsKey(field) || merged[field] == null).toList();

    return PendingIntent(
      actionType: actionType,
      extractedSlots: merged,
      missingFields: remaining,
      clarificationQuestion: clarificationQuestion,
      createdAt: createdAt,
    );
  }

  /// Checks if all mandatory fields have been fulfilled.
  bool get isComplete => missingFields.isEmpty;

  /// Converts the pending intent to a serializable JSON map.
  Map<String, dynamic> toJson() => {
        'actionType': actionType,
        'extractedSlots': extractedSlots,
        'missingFields': missingFields,
        'clarificationQuestion': clarificationQuestion,
        'createdAt': createdAt.toIso8601String(),
      };

  /// Factory constructor to restore a pending intent from JSON.
  factory PendingIntent.fromJson(Map<String, dynamic> json) {
    return PendingIntent(
      actionType: json['actionType'] as String,
      extractedSlots: Map<String, dynamic>.from(json['extractedSlots'] as Map? ?? {}),
      missingFields: (json['missingFields'] as List? ?? []).map((e) => e.toString()).toList(),
      clarificationQuestion: json['clarificationQuestion'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }

  /// Creates a copy of this pending intent with optional field overrides.
  PendingIntent copyWith({
    String? actionType,
    Map<String, dynamic>? extractedSlots,
    List<String>? missingFields,
    String? clarificationQuestion,
    DateTime? createdAt,
  }) {
    return PendingIntent(
      actionType: actionType ?? this.actionType,
      extractedSlots: extractedSlots ?? this.extractedSlots,
      missingFields: missingFields ?? this.missingFields,
      clarificationQuestion: clarificationQuestion ?? this.clarificationQuestion,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'PendingIntent(actionType: $actionType, slots: $extractedSlots, missing: $missingFields, isComplete: $isComplete)';
}
