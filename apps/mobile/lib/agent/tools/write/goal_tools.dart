import 'package:uuid/uuid.dart';
import '../agent_tool.dart';
import '../../../models/saving_goal.dart';
import '../../../providers/saving_goal_provider.dart';

/// Mutation tool to create a new saving goal.
class CreateGoalTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'goal_create';

  @override
  String get description => 'Tạo mục tiêu tích lũy / heo đất mới';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['goalName', 'targetAmount'],
    'properties': {
      'goalName': {'type': 'string'},
      'targetAmount': {'type': 'number'},
      'targetDate': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final name = input['goalName'] as String? ?? 'Mục tiêu mới';
    final double targetAmount = (input['targetAmount'] as num?)?.toDouble() ??
        (input['amount'] as num?)?.toDouble() ??
        0.0;
    if (targetAmount <= 0) return false;

    final dateStr = input['targetDate'] as String?;
    final targetDate = dateStr != null ? DateTime.tryParse(dateStr) : null;

    final goal = SavingGoal(
      id: const Uuid().v4(),
      name: name,
      targetAmount: targetAmount,
      currentAmount: 0.0,
      targetDate: targetDate,
      icon: 'savings',
      color: '#E91E63',
      status: 'active',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    return await context.ref.read(savingGoalProvider.notifier).createGoal(goal);
  }
}

/// Mutation tool to deposit funds into a saving goal.
class GoalDepositTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'goal_deposit';

  @override
  String get description => 'Bỏ heo / Nạp tiền vào mục tiêu tiết kiệm';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['amount'],
    'properties': {
      'amount': {'type': 'number'},
      'goalId': {'type': ['string', 'null']},
      'goalName': {'type': ['string', 'null']},
      'note': {'type': ['string', 'null']},
      'date': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double amount = (input['amount'] as num?)?.toDouble() ?? 0.0;
    if (amount <= 0) return false;

    final goals = context.ref.read(savingGoalProvider).value ?? [];
    final goalId = input['goalId'] as String?;
    final goalName = input['goalName'] as String?;
    final note = input['note'] as String? ?? 'Góp quỹ qua AI';
    final dateStr = input['date'] as String?;
    final date = dateStr != null ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now();

    SavingGoal? target;
    if (goalId != null) {
      target = goals.where((g) => g.id == goalId).firstOrNull;
    }
    if (target == null && goalName != null) {
      target = goals.where((g) => g.name.toLowerCase().contains(goalName.toLowerCase())).firstOrNull;
    }
    target ??= goals.firstOrNull;

    if (target == null) return false;

    return await context.ref.read(savingGoalProvider.notifier).addLog(
      goalId: target.id,
      amount: amount,
      type: 'deposit',
      logDate: date,
      note: note,
    );
  }
}

/// Mutation tool to withdraw funds from a saving goal.
class GoalWithdrawTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'goal_withdraw';

  @override
  String get description => 'Rút tiền từ mục tiêu tiết kiệm';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['amount'],
    'properties': {
      'amount': {'type': 'number'},
      'goalId': {'type': ['string', 'null']},
      'goalName': {'type': ['string', 'null']},
      'note': {'type': ['string', 'null']},
      'date': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double amount = (input['amount'] as num?)?.toDouble() ?? 0.0;
    if (amount <= 0) return false;

    final goals = context.ref.read(savingGoalProvider).value ?? [];
    final goalId = input['goalId'] as String?;
    final goalName = input['goalName'] as String?;
    final note = input['note'] as String? ?? 'Rút quỹ qua AI';
    final dateStr = input['date'] as String?;
    final date = dateStr != null ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now();

    SavingGoal? target;
    if (goalId != null) {
      target = goals.where((g) => g.id == goalId).firstOrNull;
    }
    if (target == null && goalName != null) {
      target = goals.where((g) => g.name.toLowerCase().contains(goalName.toLowerCase())).firstOrNull;
    }
    target ??= goals.firstOrNull;

    if (target == null) return false;

    return await context.ref.read(savingGoalProvider.notifier).addLog(
      goalId: target.id,
      amount: amount,
      type: 'withdraw',
      logDate: date,
      note: note,
    );
  }
}
