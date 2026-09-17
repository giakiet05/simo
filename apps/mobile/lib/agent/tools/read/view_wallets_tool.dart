import '../agent_tool.dart';
import '../../../models/ai_message.dart';
import '../../../providers/wallet_provider.dart';

/// Read tool to aggregate all wallets into a [WalletSummaryViewPayload].
class ViewWalletsTool extends SimoAgentTool<Map<String, dynamic>, WalletSummaryViewPayload?> {
  @override
  String get name => 'view_wallets';

  @override
  String get description => 'Xem tổng tài sản và danh sách số dư các ví tài khoản';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'walletId': {'type': ['string', 'null']},
    },
  };

  @override
  Future<WalletSummaryViewPayload?> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final wallets = context.ref.read(walletProvider).value ?? [];

    double totalNetWorth = 0;
    final walletItems = <WalletItemViewData>[];

    for (final w in wallets) {
      totalNetWorth += w.currentBalance;
      walletItems.add(
        WalletItemViewData(
          id: w.id,
          name: w.name,
          type: w.type,
          balance: w.currentBalance,
          icon: w.icon,
        ),
      );
    }

    return WalletSummaryViewPayload(
      totalNetWorth: totalNetWorth,
      wallets: walletItems,
    );
  }
}
