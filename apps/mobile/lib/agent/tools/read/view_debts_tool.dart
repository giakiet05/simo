import '../agent_tool.dart';
import '../../../models/ai_message.dart';
import '../../../providers/loan_provider.dart';

/// Read tool to aggregate debts into a [DebtLedgerViewPayload].
class ViewDebtsTool extends SimoAgentTool<Map<String, dynamic>, DebtLedgerViewPayload?> {
  @override
  String get name => 'view_debts';

  @override
  String get description => 'Xem danh sách các khoản nợ cần thu hoặc cần trả';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'type': {'type': 'string', 'enum': ['lent', 'borrowed', 'all']},
    },
  };

  @override
  Future<DebtLedgerViewPayload?> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final filterType = input['type'] as String? ?? 'all';
    final allLoans = context.ref.read(loanProvider).value ?? [];

    double totalReceivable = 0; // lent
    double totalPayable = 0;    // borrowed
    final items = <DebtContactItemViewData>[];

    for (final loan in allLoans) {
      if (loan.remainingAmount <= 0) continue;

      if (loan.type == 'lent') {
        totalReceivable += loan.remainingAmount;
      } else {
        totalPayable += loan.remainingAmount;
      }

      if (filterType != 'all' && loan.type != filterType) continue;

      items.add(
        DebtContactItemViewData(
          id: loan.id,
          contactName: loan.contactName,
          type: loan.type,
          remainingAmount: loan.remainingAmount,
        ),
      );
    }

    return DebtLedgerViewPayload(
      totalReceivable: totalReceivable,
      totalPayable: totalPayable,
      contacts: items,
    );
  }
}
