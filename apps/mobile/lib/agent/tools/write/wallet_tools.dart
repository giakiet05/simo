import 'package:uuid/uuid.dart';
import '../agent_tool.dart';
import '../../../models/wallet.dart';
import '../../../providers/wallet_provider.dart';

/// Mutation tool to create a new wallet.
class CreateWalletTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'wallet_create';

  @override
  String get description => 'Tạo ví tiền hoặc tài khoản ngân hàng mới';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['walletName'],
    'properties': {
      'walletName': {'type': 'string'},
      'walletType': {'type': 'string', 'enum': ['cash', 'bank', 'e_wallet', 'credit']},
      'amount': {'type': 'number'},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final name = input['walletName'] as String? ?? 'Ví mới';
    final type = input['walletType'] as String? ?? 'bank';
    final initialBalance = (input['amount'] as num?)?.toDouble() ?? 0.0;

    final wallet = Wallet(
      id: const Uuid().v4(),
      name: name,
      type: type,
      initialBalance: initialBalance,
      currentBalance: initialBalance,
      currency: 'VND',
      icon: _getDefaultIcon(type),
      color: _getDefaultColor(type),
      isDefault: false,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await context.ref.read(walletProvider.notifier).createWallet(wallet);
    return true;
  }

  String _getDefaultIcon(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return 'payments';
      case 'bank':
        return 'account_balance';
      case 'e_wallet':
        return 'smartphone';
      case 'credit':
        return 'credit_card';
      default:
        return 'account_balance_wallet';
    }
  }

  String _getDefaultColor(String type) {
    switch (type.toLowerCase()) {
      case 'cash':
        return '#4CAF50';
      case 'bank':
        return '#2196F3';
      case 'e_wallet':
        return '#E91E63';
      case 'credit':
        return '#9C27B0';
      default:
        return '#607D8B';
    }
  }
}

/// Mutation tool to adjust an existing wallet's balance.
class AdjustWalletBalanceTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'wallet_adjust_balance';

  @override
  String get description => 'Điều chỉnh số dư thực tế của một ví';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['newBalance'],
    'properties': {
      'walletId': {'type': ['string', 'null']},
      'walletName': {'type': ['string', 'null']},
      'newBalance': {'type': 'number'},
      'note': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double? newBalance = (input['newBalance'] as num?)?.toDouble() ??
        (input['amount'] as num?)?.toDouble();
    if (newBalance == null) return false;

    final wallets = context.ref.read(walletProvider).value ?? [];
    final walletId = input['walletId'] as String?;
    final walletName = input['walletName'] as String?;

    Wallet? target;
    if (walletId != null && walletId.isNotEmpty) {
      target = wallets.where((w) => w.id == walletId).firstOrNull;
    }
    if (target == null && walletName != null && walletName.isNotEmpty) {
      target = wallets.where((w) => w.name.toLowerCase().contains(walletName.toLowerCase())).firstOrNull;
    }
    target ??= wallets.where((w) => w.isDefault).firstOrNull ?? (wallets.isNotEmpty ? wallets.first : null);

    if (target == null) return false;

    final updated = target.copyWith(
      currentBalance: newBalance,
      updatedAt: DateTime.now(),
    );

    await context.ref.read(walletProvider.notifier).updateWallet(updated);
    return true;
  }
}

/// Mutation tool to transfer funds between wallets.
class TransferWalletTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'transfer';

  @override
  String get description => 'Chuyển tiền qua lại giữa 2 ví';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['amount'],
    'properties': {
      'amount': {'type': 'number'},
      'sourceWalletId': {'type': ['string', 'null']},
      'destinationWalletId': {'type': ['string', 'null']},
      'fee': {'type': ['number', 'null']},
      'note': {'type': ['string', 'null']},
      'date': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double amount = (input['amount'] as num?)?.toDouble() ?? 0.0;
    if (amount <= 0) return false;

    final double fee = (input['fee'] as num?)?.toDouble() ?? 0.0;
    final note = input['note'] as String? ?? 'Chuyển tiền qua AI';
    final dateStr = input['date'] as String?;
    final date = dateStr != null ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now();

    final wallets = context.ref.read(walletProvider).value ?? [];
    if (wallets.length < 2) return false;

    String? srcId = input['sourceWalletId'] as String?;
    String? dstId = input['destinationWalletId'] as String?;

    if (srcId == null || !wallets.any((w) => w.id == srcId)) {
      srcId = wallets.first.id;
    }
    if (dstId == null || !wallets.any((w) => w.id == dstId) || dstId == srcId) {
      dstId = wallets.firstWhere((w) => w.id != srcId).id;
    }

    await context.ref.read(walletProvider.notifier).transferFunds(
      sourceWalletId: srcId,
      destinationWalletId: dstId,
      amount: amount,
      fee: fee,
      transferDate: date,
      note: note,
    );

    return true;
  }
}
