import '../agent_tool.dart';
import '../../../models/ai_message.dart';
import '../../../providers/saving_goal_provider.dart';

/// Read tool to aggregate saving goals into a [SavingGoalsViewPayload].
class ViewGoalsTool extends SimoAgentTool<Map<String, dynamic>, SavingGoalsViewPayload?> {
  @override
  String get name => 'view_goals';

  @override
  String get description => 'Xem danh sách tiến độ các mục tiêu tích lũy và heo đất';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'goalId': {'type': ['string', 'null']},
    },
  };

  @override
  Future<SavingGoalsViewPayload?> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final allGoals = context.ref.read(savingGoalProvider).value ?? [];
    final goalId = input['goalId'] as String?;

    final filtered = allGoals.where((g) {
      if (goalId != null && goalId.isNotEmpty && g.id != goalId) {
        return false;
      }
      return true;
    }).toList();

    final items = <SavingGoalItemViewData>[];
    for (final g in filtered) {
      final pct = g.targetAmount > 0 ? (g.currentAmount / g.targetAmount) : 0.0;
      items.add(
        SavingGoalItemViewData(
          id: g.id,
          name: g.name,
          targetAmount: g.targetAmount,
          currentAmount: g.currentAmount,
          percentage: pct,
          targetDate: g.targetDate,
        ),
      );
    }

    return SavingGoalsViewPayload(goals: items);
  }
}
