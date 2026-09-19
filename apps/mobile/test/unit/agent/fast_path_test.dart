import 'package:flutter_test/flutter_test.dart';
import 'package:simo/agent/tools/navigation/navigate_screen_tool.dart';
import 'package:simo/agent/tools/read/query_transactions_tool.dart';
import 'package:simo/agent/tools/read/view_wallets_tool.dart';
import 'package:simo/agent/tools/read/view_debts_tool.dart';
import 'package:simo/agent/tools/read/view_goals_tool.dart';
import 'package:simo/agent/tools/read/view_budgets_tool.dart';
import 'package:simo/agent/tools/tool_registry.dart';

void main() {
  group('Fast-Path Read & Navigation Tools Tests', () {
    test('read and navigation tools are correctly configured with parameters schemas', () {
      final navTool = NavigateScreenTool();
      expect(navTool.name, equals('navigate_screen'));
      expect(navTool.parametersSchema['properties'], contains('destination'));

      final queryTx = QueryTransactionsTool();
      expect(queryTx.name, equals('query_transactions'));
      expect(queryTx.parametersSchema['properties'], contains('period'));
      expect(queryTx.parametersSchema['properties'], contains('type'));

      final viewWallets = ViewWalletsTool();
      expect(viewWallets.name, equals('view_wallets'));

      final viewDebts = ViewDebtsTool();
      expect(viewDebts.name, equals('view_debts'));

      final viewGoals = ViewGoalsTool();
      expect(viewGoals.name, equals('view_goals'));

      final viewBudgets = ViewBudgetsTool();
      expect(viewBudgets.name, equals('view_budgets'));
    });

    test('ToolRegistry includes all fast path tools', () {
      final registry = ToolRegistry();
      registry.register(NavigateScreenTool());
      registry.register(QueryTransactionsTool());
      registry.register(ViewWalletsTool());
      registry.register(ViewDebtsTool());
      registry.register(ViewGoalsTool());
      registry.register(ViewBudgetsTool());

      expect(registry.hasTool('navigate_screen'), isTrue);
      expect(registry.hasTool('query_transactions'), isTrue);
      expect(registry.hasTool('view_wallets'), isTrue);
      expect(registry.hasTool('view_debts'), isTrue);
      expect(registry.hasTool('view_goals'), isTrue);
      expect(registry.hasTool('view_budgets'), isTrue);
    });
  });
}
