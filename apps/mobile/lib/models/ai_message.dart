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
}

/// Payload for rendering the [AiWalletSummaryCard].
class WalletSummaryViewPayload extends AiViewPayload {
  final double totalNetWorth;
  final List<WalletItemViewData> wallets;

  const WalletSummaryViewPayload({
    required this.totalNetWorth,
    required this.wallets,
  });
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
}

/// Payload for rendering the [AiSavingGoalsCard].
class SavingGoalsViewPayload extends AiViewPayload {
  final List<SavingGoalItemViewData> goals;

  const SavingGoalsViewPayload({
    required this.goals,
  });
}

/// Represents an individual chat message in the conversational AI Assistant stream.
class AiMessage {
  /// Unique identifier of the message.
  final String id;

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
    required this.role,
    required this.content,
    required this.timestamp,
    this.status = AiMessageStatus.idle,
    this.errorMessage,
    this.actions = const [],
    this.viewPayload,
  });

  /// Convenience constructor to instantiate a new user message.
  factory AiMessage.user(String content) {
    return AiMessage(
      id: const Uuid().v4(),
      role: AiMessageRole.user,
      content: content,
      timestamp: DateTime.now(),
      status: AiMessageStatus.idle,
    );
  }

  /// Convenience constructor to instantiate an assistant placeholder message while processing.
  factory AiMessage.assistantThinking() {
    return AiMessage(
      id: const Uuid().v4(),
      role: AiMessageRole.assistant,
      content: '',
      timestamp: DateTime.now(),
      status: AiMessageStatus.thinking,
    );
  }

  /// Convenience constructor to instantiate a completed assistant message.
  factory AiMessage.assistant({
    required String content,
    List<AiExecutedAction> actions = const [],
    AiViewPayload? viewPayload,
  }) {
    return AiMessage(
      id: const Uuid().v4(),
      role: AiMessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      status: AiMessageStatus.executed,
      actions: actions,
      viewPayload: viewPayload,
    );
  }

  /// Convenience constructor to instantiate an error assistant message.
  factory AiMessage.error({
    required String errorMessage,
    String content = '',
  }) {
    return AiMessage(
      id: const Uuid().v4(),
      role: AiMessageRole.assistant,
      content: content,
      timestamp: DateTime.now(),
      status: AiMessageStatus.error,
      errorMessage: errorMessage,
    );
  }

  /// Creates a copy of this message with updated fields.
  AiMessage copyWith({
    String? id,
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
