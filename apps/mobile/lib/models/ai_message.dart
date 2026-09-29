import 'dart:convert';
import 'package:uuid/uuid.dart';

/// Role of the message participant in the AI conversation.
enum AiMessageRole {
  user,
  assistant,
  system,
}

/// Execution and delivery status of an AI message.
enum AiMessageStatus {
  idle,
  sending,
  thinking,
  executed,
  error,
}

/// Represents an individual structured action executed by the AI agent.
class AiExecutedAction {
  /// The specific operation type performed (e.g., transaction_create, transfer, budget_set).
  final String actionType;

  /// High-level readable title for presentation (e.g. "Chi tiêu", "Đặt ngân sách").
  final String title;

  /// Standardized numerical amount in local currency (VND).
  final double amount;

  /// Descriptive subtitle with entity details (e.g., wallet names, category).
  final String subtitle;

  /// Timestamp associated with the action.
  final DateTime date;

  /// Indicates whether the local database persistence succeeded.
  final bool isSuccess;

  /// Raw action payload received from the model parser.
  final Map<String, dynamic>? rawAction;

  const AiExecutedAction({
    required this.actionType,
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.date,
    this.isSuccess = true,
    this.rawAction,
  });

  /// Converts this executed action into a serializable Map for persistence.
  Map<String, dynamic> toMap() {
    return {
      'actionType': actionType,
      'title': title,
      'amount': amount,
      'subtitle': subtitle,
      'date': date.toIso8601String(),
      'isSuccess': isSuccess ? 1 : 0,
      'rawAction': rawAction,
    };
  }

  /// Instantiates an [AiExecutedAction] from a serialized Map representation.
  factory AiExecutedAction.fromMap(Map<String, dynamic> map) {
    final double parsedAmount = (map['amount'] as num?)?.toDouble() ?? 0.0;
    final dateStr = map['date'] as String?;
    final DateTime parsedDate = dateStr != null
        ? (DateTime.tryParse(dateStr) ?? DateTime.now())
        : DateTime.now();

    final dynamic successValue = map['isSuccess'];
    final bool isSuccess = successValue == 1 || successValue == true;

    return AiExecutedAction(
      actionType: map['actionType'] as String? ?? 'transaction_create',
      title: map['title'] as String? ?? '',
      amount: parsedAmount,
      subtitle: map['subtitle'] as String? ?? '',
      date: parsedDate,
      isSuccess: isSuccess,
      rawAction: map['rawAction'] is Map
          ? Map<String, dynamic>.from(map['rawAction'] as Map)
          : null,
    );
  }

  /// Factory constructor to convert a raw parsed action map to an executed action representation.
  factory AiExecutedAction.fromRawAction({
    required Map<String, dynamic> rawAction,
    required String title,
    required String subtitle,
    bool isSuccess = true,
  }) {
    final double amount = (rawAction['amount'] as num?)?.toDouble() ?? 0.0;
    final dateStr = rawAction['date'] as String?;
    final DateTime parsedDate = dateStr != null
        ? (DateTime.tryParse(dateStr) ?? DateTime.now())
        : DateTime.now();

    return AiExecutedAction(
      actionType: rawAction['actionType'] as String? ?? 'transaction_create',
      title: title,
      amount: amount,
      subtitle: subtitle,
      date: parsedDate,
      isSuccess: isSuccess,
      rawAction: rawAction,
    );
  }
}

/// Base class for rich interactive Generative UI cards displayed in the chat stream.
abstract class AiViewPayload {
  const AiViewPayload();

  /// Converts this view payload to a serializable Map.
  Map<String, dynamic> toMap();

  /// Deserializes an [AiViewPayload] based on its discriminator type.
  static AiViewPayload? fromMap(Map<String, dynamic>? map) {
    if (map == null) return null;
    final type = map['type'] as String?;
    switch (type) {
      case 'transaction_list':
        return TransactionListViewPayload.fromMap(map);
      case 'wallet_summary':
        return WalletSummaryViewPayload.fromMap(map);
      case 'budget_progress':
        return BudgetProgressViewPayload.fromMap(map);
      case 'debt_ledger':
        return DebtLedgerViewPayload.fromMap(map);
      case 'saving_goals':
        return SavingGoalsViewPayload.fromMap(map);
      default:
        return null;
    }
  }
}

/// Data for a single transaction item in a query view card.
class TransactionItemViewData {
  final String id;
  final double amount;
  final String type; // 'expense' or 'income'
  final String note;
  final String categoryName;
  final String categoryIcon;
  final String categoryColor;
  final String walletName;
  final DateTime date;

  const TransactionItemViewData({
    required this.id,
    required this.amount,
    required this.type,
    required this.note,
    required this.categoryName,
    required this.categoryIcon,
    required this.categoryColor,
    required this.walletName,
    required this.date,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'amount': amount,
        'type': type,
        'note': note,
        'categoryName': categoryName,
        'categoryIcon': categoryIcon,
        'categoryColor': categoryColor,
        'walletName': walletName,
        'date': date.toIso8601String(),
      };

  factory TransactionItemViewData.fromMap(Map<String, dynamic> map) {
    return TransactionItemViewData(
      id: map['id'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      type: map['type'] as String? ?? 'expense',
      note: map['note'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      categoryIcon: map['categoryIcon'] as String? ?? '',
      categoryColor: map['categoryColor'] as String? ?? '',
      walletName: map['walletName'] as String? ?? '',
      date: DateTime.tryParse(map['date'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// Payload for rendering the [AiTransactionListCard].
class TransactionListViewPayload extends AiViewPayload {
  final String title;
  final double totalAmount;
  final String period;
  final List<TransactionItemViewData> transactions;

  const TransactionListViewPayload({
    required this.title,
    required this.totalAmount,
    required this.period,
    required this.transactions,
  });

  @override
  Map<String, dynamic> toMap() => {
        'type': 'transaction_list',
        'title': title,
        'totalAmount': totalAmount,
        'period': period,
        'transactions': transactions.map((t) => t.toMap()).toList(),
      };

  factory TransactionListViewPayload.fromMap(Map<String, dynamic> map) {
    final list = map['transactions'] as List? ?? [];
    return TransactionListViewPayload(
      title: map['title'] as String? ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      period: map['period'] as String? ?? '',
      transactions: list
          .map((item) =>
              TransactionItemViewData.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

/// Data for a single wallet item in the summary card.
class WalletItemViewData {
  final String id;
  final String name;
  final String type;
  final double balance;
  final String icon;

  const WalletItemViewData({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    required this.icon,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'type': type,
        'balance': balance,
        'icon': icon,
      };

  factory WalletItemViewData.fromMap(Map<String, dynamic> map) {
    return WalletItemViewData(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'cash',
      balance: (map['balance'] as num?)?.toDouble() ?? 0.0,
      icon: map['icon'] as String? ?? 'wallet',
    );
  }
}

/// Payload for rendering the [AiWalletSummaryCard].
class WalletSummaryViewPayload extends AiViewPayload {
  final double totalNetWorth;
  final List<WalletItemViewData> wallets;

  const WalletSummaryViewPayload({
    required this.totalNetWorth,
    required this.wallets,
  });

  @override
  Map<String, dynamic> toMap() => {
        'type': 'wallet_summary',
        'totalNetWorth': totalNetWorth,
        'wallets': wallets.map((w) => w.toMap()).toList(),
      };

  factory WalletSummaryViewPayload.fromMap(Map<String, dynamic> map) {
    final list = map['wallets'] as List? ?? [];
    return WalletSummaryViewPayload(
      totalNetWorth: (map['totalNetWorth'] as num?)?.toDouble() ?? 0.0,
      wallets: list
          .map((item) =>
              WalletItemViewData.fromMap(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

/// Data for a category budget item.
class CategoryBudgetItemViewData {
  final String categoryId;
  final String categoryName;
  final String categoryIcon;
  final double limitAmount;
  final double spentAmount;
  final double percentage; // 0.0 to 1.0+

  const CategoryBudgetItemViewData({
    required this.categoryId,
    required this.categoryName,
    required this.categoryIcon,
    required this.limitAmount,
    required this.spentAmount,
    required this.percentage,
  });

  Map<String, dynamic> toMap() => {
        'categoryId': categoryId,
        'categoryName': categoryName,
        'categoryIcon': categoryIcon,
        'limitAmount': limitAmount,
        'spentAmount': spentAmount,
        'percentage': percentage,
      };

  factory CategoryBudgetItemViewData.fromMap(Map<String, dynamic> map) {
    return CategoryBudgetItemViewData(
      categoryId: map['categoryId'] as String? ?? '',
      categoryName: map['categoryName'] as String? ?? '',
      categoryIcon: map['categoryIcon'] as String? ?? '',
      limitAmount: (map['limitAmount'] as num?)?.toDouble() ?? 0.0,
      spentAmount: (map['spentAmount'] as num?)?.toDouble() ?? 0.0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Payload for rendering the [AiBudgetProgressCard].
class BudgetProgressViewPayload extends AiViewPayload {
  final String month;
  final double totalLimit;
  final double totalSpent;
  final double totalPercentage;
  final List<CategoryBudgetItemViewData> categories;

  const BudgetProgressViewPayload({
    required this.month,
    required this.totalLimit,
    required this.totalSpent,
    required this.totalPercentage,
    required this.categories,
  });

  @override
  Map<String, dynamic> toMap() => {
        'type': 'budget_progress',
        'month': month,
        'totalLimit': totalLimit,
        'totalSpent': totalSpent,
        'totalPercentage': totalPercentage,
        'categories': categories.map((c) => c.toMap()).toList(),
      };

  factory BudgetProgressViewPayload.fromMap(Map<String, dynamic> map) {
    final list = map['categories'] as List? ?? [];
    return BudgetProgressViewPayload(
      month: map['month'] as String? ?? '',
      totalLimit: (map['totalLimit'] as num?)?.toDouble() ?? 0.0,
      totalSpent: (map['totalSpent'] as num?)?.toDouble() ?? 0.0,
      totalPercentage: (map['totalPercentage'] as num?)?.toDouble() ?? 0.0,
      categories: list
          .map((item) => CategoryBudgetItemViewData.fromMap(
              Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

/// Data for a single debt contact item.
class DebtContactItemViewData {
  final String id;
  final String contactName;
  final String type; // 'lent' (they owe me) or 'borrowed' (I owe them)
  final double remainingAmount;

  const DebtContactItemViewData({
    required this.id,
    required this.contactName,
    required this.type,
    required this.remainingAmount,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'contactName': contactName,
        'type': type,
        'remainingAmount': remainingAmount,
      };

  factory DebtContactItemViewData.fromMap(Map<String, dynamic> map) {
    return DebtContactItemViewData(
      id: map['id'] as String? ?? '',
      contactName: map['contactName'] as String? ?? '',
      type: map['type'] as String? ?? 'lent',
      remainingAmount: (map['remainingAmount'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

/// Payload for rendering the [AiDebtLedgerCard].
class DebtLedgerViewPayload extends AiViewPayload {
  final double totalReceivable; // They owe me
  final double totalPayable;    // I owe them
  final List<DebtContactItemViewData> contacts;

  const DebtLedgerViewPayload({
    required this.totalReceivable,
    required this.totalPayable,
    required this.contacts,
  });

  @override
  Map<String, dynamic> toMap() => {
        'type': 'debt_ledger',
        'totalReceivable': totalReceivable,
        'totalPayable': totalPayable,
        'contacts': contacts.map((c) => c.toMap()).toList(),
      };

  factory DebtLedgerViewPayload.fromMap(Map<String, dynamic> map) {
    final list = map['contacts'] as List? ?? [];
    return DebtLedgerViewPayload(
      totalReceivable: (map['totalReceivable'] as num?)?.toDouble() ?? 0.0,
      totalPayable: (map['totalPayable'] as num?)?.toDouble() ?? 0.0,
      contacts: list
          .map((item) => DebtContactItemViewData.fromMap(
              Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

/// Data for a single saving goal item.
class SavingGoalItemViewData {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final double percentage;
  final DateTime? targetDate;

  const SavingGoalItemViewData({
    required this.id,
    required this.name,
    required this.targetAmount,
    required this.currentAmount,
    required this.percentage,
    this.targetDate,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'percentage': percentage,
        'targetDate': targetDate?.toIso8601String(),
      };

  factory SavingGoalItemViewData.fromMap(Map<String, dynamic> map) {
    final targetDateStr = map['targetDate'] as String?;
    return SavingGoalItemViewData(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0.0,
      percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
      targetDate: targetDateStr != null ? DateTime.tryParse(targetDateStr) : null,
    );
  }
}

/// Payload for rendering the [AiSavingGoalsCard].
class SavingGoalsViewPayload extends AiViewPayload {
  final List<SavingGoalItemViewData> goals;

  const SavingGoalsViewPayload({
    required this.goals,
  });

  @override
  Map<String, dynamic> toMap() => {
        'type': 'saving_goals',
        'goals': goals.map((g) => g.toMap()).toList(),
      };

  factory SavingGoalsViewPayload.fromMap(Map<String, dynamic> map) {
    final list = map['goals'] as List? ?? [];
    return SavingGoalsViewPayload(
      goals: list
          .map((item) => SavingGoalItemViewData.fromMap(
              Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

/// Represents an individual chat message in the conversational AI Assistant stream.
class AiMessage {
  /// Unique identifier of the message.
  final String id;

  /// Identifier of the conversational turn (groups user request and assistant responses together).
  final String turnId;

  /// Participant role for this turn (user or assistant).
  final AiMessageRole role;

  /// Text content of the dialogue turn.
  final String content;

  /// Creation timestamp.
  final DateTime timestamp;

  /// Current processing or delivery state.
  final AiMessageStatus status;

  /// Detailed human-readable error description when status is error.
  final String? errorMessage;

  /// List of structured operations performed alongside this assistant turn.
  final List<AiExecutedAction> actions;

  /// Optional rich visual data payload for Generative UI view cards.
  final AiViewPayload? viewPayload;

  const AiMessage({
    required this.id,
    required this.turnId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.status = AiMessageStatus.idle,
    this.errorMessage,
    this.actions = const [],
    this.viewPayload,
  });

  /// Convenience constructor to instantiate a new user message.
  factory AiMessage.user(
    String content, {
    String? id,
    String? turnId,
    DateTime? timestamp,
  }) {
    return AiMessage(
      id: id ?? const Uuid().v4(),
      turnId: turnId ?? const Uuid().v4(),
      role: AiMessageRole.user,
      content: content,
      timestamp: timestamp ?? DateTime.now(),
      status: AiMessageStatus.idle,
    );
  }

  /// Convenience constructor to instantiate an assistant placeholder message while processing.
  factory AiMessage.assistantThinking({
    String? id,
    String? turnId,
  }) {
    return AiMessage(
      id: id ?? const Uuid().v4(),
      turnId: turnId ?? const Uuid().v4(),
      role: AiMessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      status: AiMessageStatus.thinking,
    );
  }

  /// Convenience constructor to instantiate a completed assistant message.
  factory AiMessage.assistant({
    required String content,
    String? turnId,
    List<AiExecutedAction> actions = const [],
    AiViewPayload? viewPayload,
    String? id,
    DateTime? timestamp,
  }) {
    return AiMessage(
      id: id ?? const Uuid().v4(),
      turnId: turnId ?? const Uuid().v4(),
      role: AiMessageRole.assistant,
      content: content,
      timestamp: timestamp ?? DateTime.now(),
      status: AiMessageStatus.executed,
      actions: actions,
      viewPayload: viewPayload,
    );
  }

  /// Convenience constructor to instantiate an error assistant message.
  factory AiMessage.error({
    required String errorMessage,
    String? turnId,
    String content = '',
    String? id,
    DateTime? timestamp,
  }) {
    return AiMessage(
      id: id ?? const Uuid().v4(),
      turnId: turnId ?? const Uuid().v4(),
      role: AiMessageRole.assistant,
      content: content,
      timestamp: timestamp ?? DateTime.now(),
      status: AiMessageStatus.error,
      errorMessage: errorMessage,
    );
  }

  /// Converts this message into a SQLite map for persistence.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'turn_id': turnId,
      'role': role.name,
      'content': content,
      'timestamp': timestamp.toIso8601String(),
      'status': status.name,
      'error_message': errorMessage,
      'actions_json': actions.isNotEmpty
          ? jsonEncode(actions.map((a) => a.toMap()).toList())
          : null,
      'view_payload_json':
          viewPayload != null ? jsonEncode(viewPayload!.toMap()) : null,
    };
  }

  /// Instantiates an [AiMessage] from a SQLite map representation.
  factory AiMessage.fromMap(Map<String, dynamic> map) {
    List<AiExecutedAction> actions = const [];
    final actionsRaw = map['actions_json'];
    if (actionsRaw != null && actionsRaw is String && actionsRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(actionsRaw);
        if (decoded is List) {
          actions = decoded
              .map((e) =>
                  AiExecutedAction.fromMap(Map<String, dynamic>.from(e as Map)))
              .toList();
        }
      } catch (_) {}
    }

    AiViewPayload? viewPayload;
    final payloadRaw = map['view_payload_json'];
    if (payloadRaw != null && payloadRaw is String && payloadRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(payloadRaw);
        if (decoded is Map) {
          viewPayload =
              AiViewPayload.fromMap(Map<String, dynamic>.from(decoded));
        }
      } catch (_) {}
    }

    final roleStr = map['role'] as String? ?? 'user';
    final role = AiMessageRole.values.firstWhere(
      (r) => r.name == roleStr,
      orElse: () => AiMessageRole.user,
    );

    final statusStr = map['status'] as String? ?? 'idle';
    final status = AiMessageStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => AiMessageStatus.idle,
    );

    return AiMessage(
      id: map['id'] as String? ?? const Uuid().v4(),
      turnId: map['turn_id'] as String? ?? const Uuid().v4(),
      role: role,
      content: map['content'] as String? ?? '',
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ??
          DateTime.now(),
      status: status,
      errorMessage: map['error_message'] as String?,
      actions: actions,
      viewPayload: viewPayload,
    );
  }

  /// Creates a copy of this message with updated fields.
  AiMessage copyWith({
    String? id,
    String? turnId,
    AiMessageRole? role,
    String? content,
    DateTime? timestamp,
    AiMessageStatus? status,
    String? errorMessage,
    List<AiExecutedAction>? actions,
    AiViewPayload? viewPayload,
  }) {
    return AiMessage(
      id: id ?? this.id,
      turnId: turnId ?? this.turnId,
      role: role ?? this.role,
      content: content ?? this.content,
      timestamp: timestamp ?? this.timestamp,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      actions: actions ?? this.actions,
      viewPayload: viewPayload ?? this.viewPayload,
    );
  }
}
