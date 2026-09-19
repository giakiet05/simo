import 'package:flutter_test/flutter_test.dart';
import 'package:simo/agent/tools/tool_registry.dart';
import 'package:simo/agent/tools/write/wallet_tools.dart';
import 'package:simo/agent/tools/write/loan_tools.dart';
import 'package:simo/agent/tools/write/goal_tools.dart';
import 'package:simo/agent/tools/write/recurring_tools.dart';
import 'package:simo/agent/tools/write/budget_tools.dart';
import 'package:simo/agent/brain/tool_specs.dart';

void main() {
  group('Full CRUD Tools Definition & Registry Tests', () {
    test('all new CRUD tools are properly registered and retrievable by name', () {
      final registry = ToolRegistry();

      registry.register(CreateWalletTool());
      registry.register(UpdateWalletTool());
      registry.register(DeleteWalletTool());
      registry.register(AdjustWalletBalanceTool());
      registry.register(TransferWalletTool());

      registry.register(CreateLoanTool());
      registry.register(UpdateLoanTool());
      registry.register(DeleteLoanTool());
      registry.register(RepayLoanTool());

      registry.register(CreateGoalTool());
      registry.register(UpdateGoalTool());
      registry.register(DeleteGoalTool());
      registry.register(GoalDepositTool());
      registry.register(GoalWithdrawTool());

      registry.register(CreateRecurringTool());
      registry.register(UpdateRecurringTool());
      registry.register(DeleteRecurringTool());

      registry.register(SetBudgetTool());
      registry.register(DeleteBudgetTool());

      expect(registry.hasTool('wallet_update'), isTrue);
      expect(registry.hasTool('wallet_delete'), isTrue);
      expect(registry.hasTool('loan_update'), isTrue);
      expect(registry.hasTool('loan_delete'), isTrue);
      expect(registry.hasTool('goal_update'), isTrue);
      expect(registry.hasTool('goal_delete'), isTrue);
      expect(registry.hasTool('recurring_update'), isTrue);
      expect(registry.hasTool('recurring_delete'), isTrue);
      expect(registry.hasTool('budget_delete'), isTrue);
    });

    test('OpenAiToolSpecs correctly transforms all registered tools to OpenAI tool models', () {
      final registry = ToolRegistry();
      registry.register(UpdateWalletTool());
      registry.register(DeleteWalletTool());
      registry.register(UpdateLoanTool());
      registry.register(DeleteLoanTool());
      registry.register(UpdateGoalTool());
      registry.register(DeleteGoalTool());
      registry.register(UpdateRecurringTool());
      registry.register(DeleteRecurringTool());
      registry.register(DeleteBudgetTool());

      final specs = OpenAiToolSpecs.fromRegistry(registry);
      expect(specs.length, equals(9));
      expect(specs.any((s) => s.function.name == 'wallet_update'), isTrue);
      expect(specs.any((s) => s.function.name == 'loan_update'), isTrue);
      expect(specs.any((s) => s.function.name == 'goal_delete'), isTrue);
      expect(specs.any((s) => s.function.name == 'recurring_update'), isTrue);
      expect(specs.any((s) => s.function.name == 'budget_delete'), isTrue);
    });

    test('validates parameter schemas for update and delete tools', () {
      final walletUpdate = UpdateWalletTool();
      expect(walletUpdate.parametersSchema['type'], equals('object'));
      expect(walletUpdate.parametersSchema['properties'], contains('newName'));
      expect(walletUpdate.parametersSchema['properties'], contains('walletType'));

      final loanUpdate = UpdateLoanTool();
      expect(loanUpdate.parametersSchema['properties'], contains('remainingAmount'));
      expect(loanUpdate.parametersSchema['properties'], contains('dueDate'));

      final goalUpdate = UpdateGoalTool();
      expect(goalUpdate.parametersSchema['properties'], contains('targetAmount'));
      expect(goalUpdate.parametersSchema['properties'], contains('targetDate'));

      final recurringUpdate = UpdateRecurringTool();
      expect(recurringUpdate.parametersSchema['properties'], contains('dayOfMonth'));
      expect(recurringUpdate.parametersSchema['properties'], contains('isActive'));

      final budgetDelete = DeleteBudgetTool();
      expect(budgetDelete.parametersSchema['properties'], contains('categoryId'));
    });
  });
}
