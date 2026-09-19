import 'package:uuid/uuid.dart';
import '../agent_tool.dart';
import '../../../models/wallet.dart';
import '../../../providers/wallet_provider.dart';

/// Mutation tool to create a new wallet.
class CreateWalletTool extends SimoAgentTool<Map<String, dynamic>, Map<String, dynamic>> {
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
      'walletType': {'type': 'string', 'enum': ['cash', 'bank', 'e_wallet', 'credit', 'savings', 'other']},
      'amount': {'type': 'number'},
      'isDefault': {'type': 'boolean'},
    },
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final name = input['walletName'] as String? ?? 'Ví mới';
    final type = input['walletType'] as String? ?? 'bank';
    final initialBalance = (input['amount'] as num?)?.toDouble() ?? 0.0;
    final isDefault = input['isDefault'] as bool? ?? false;
    final generatedId = const Uuid().v4();

    final wallet = Wallet(
      id: generatedId,
      name: name,
      type: type,
      initialBalance: initialBalance,
      currentBalance: initialBalance,
      currency: 'VND',
      icon: _getDefaultIcon(type),
      color: _getDefaultColor(type),
      isDefault: isDefault,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await context.ref.read(walletProvider.notifier).createWallet(wallet);
    return {
      'isSuccess': true,
      'walletId': generatedId,
      'walletName': name,
      'currentBalance': initialBalance,
      'type': type,
      'isDefault': isDefault,
    };
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
      case 'savings':
        return 'savings';
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
      case 'savings':
        return '#FF9800';
      default:
        return '#607D8B';
    }
  }
}

/// Mutation tool to update an existing wallet's details (name, type, default status).
class UpdateWalletTool extends SimoAgentTool<Map<String, dynamic>, Map<String, dynamic>> {
  @override
  String get name => 'wallet_update';

  @override
  String get description => 'Đổi tên ví, loại ví, hoặc đặt làm ví mặc định';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'walletId': {'type': ['string', 'null']},
      'walletName': {'type': ['string', 'null']},
      'newName': {'type': ['string', 'null']},
      'walletType': {'type': ['string', 'null'], 'enum': ['cash', 'bank', 'e_wallet', 'credit', 'savings', 'other']},
      'isDefault': {'type': ['boolean', 'null']},
    },
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    List<Wallet> wallets = context.ref.read(walletProvider).value ?? [];
    if (wallets.isEmpty) {
      wallets = await context.ref.read(walletRepositoryProvider).getAllWallets();
    }
    final walletId = input['walletId'] as String?;
    final walletName = input['walletName'] as String?;
    final newName = input['newName'] as String?;
    final walletType = input['walletType'] as String?;
    final isDefault = input['isDefault'] as bool?;

    Wallet? target;
    if (walletId != null && walletId.isNotEmpty) {
      target = wallets.where((w) => w.id == walletId).firstOrNull;
    }
    if (target == null && walletName != null && walletName.isNotEmpty) {
      target = wallets.where((w) => w.name.toLowerCase().contains(walletName.toLowerCase())).firstOrNull;
    }

    if (target == null) return {'isSuccess': false, 'error': 'Không tìm thấy ví cần sửa'};

    if (isDefault == true) {
      await context.ref.read(walletProvider.notifier).setDefaultWallet(target.id);
    }

    final updated = target.copyWith(
      name: newName ?? target.name,
      type: walletType ?? target.type,
      isDefault: isDefault ?? target.isDefault,
      updatedAt: DateTime.now(),
    );

    await context.ref.read(walletProvider.notifier).updateWallet(updated);
    return {
      'isSuccess': true,
      'walletId': target.id,
      'walletName': updated.name,
      'type': updated.type,
      'isDefault': updated.isDefault,
    };
  }
}

/// Mutation tool to delete an existing wallet.
class DeleteWalletTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'wallet_delete';

  @override
  String get description => 'Xóa ví hoặc tài khoản ngân hàng';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'walletId': {'type': ['string', 'null']},
      'walletName': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    List<Wallet> wallets = context.ref.read(walletProvider).value ?? [];
    if (wallets.isEmpty) {
      wallets = await context.ref.read(walletRepositoryProvider).getAllWallets();
    }
    final walletId = input['walletId'] as String?;
    final walletName = input['walletName'] as String?;

    Wallet? target;
    if (walletId != null && walletId.isNotEmpty) {
      target = wallets.where((w) => w.id == walletId).firstOrNull;
    }
    if (target == null && walletName != null && walletName.isNotEmpty) {
      target = wallets.where((w) => w.name.toLowerCase().contains(walletName.toLowerCase())).firstOrNull;
    }

    if (target == null) return false;

    await context.ref.read(walletProvider.notifier).deleteWallet(target.id);
    return true;
  }
}

/// Mutation tool to adjust an existing wallet's balance.
class AdjustWalletBalanceTool extends SimoAgentTool<Map<String, dynamic>, Map<String, dynamic>> {
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
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double? newBalance = (input['newBalance'] as num?)?.toDouble() ??
        (input['amount'] as num?)?.toDouble();
    if (newBalance == null) return {'isSuccess': false, 'error': 'Số dư mới không hợp lệ'};

    List<Wallet> wallets = context.ref.read(walletProvider).value ?? [];
    if (wallets.isEmpty) {
      wallets = await context.ref.read(walletRepositoryProvider).getAllWallets();
    }
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

    if (target == null) return {'isSuccess': false, 'error': 'Không tìm thấy ví cần điều chỉnh số dư'};

    final updated = target.copyWith(
      currentBalance: newBalance,
      updatedAt: DateTime.now(),
    );

    await context.ref.read(walletProvider.notifier).updateWallet(updated);
    return {
      'isSuccess': true,
      'walletId': target.id,
      'walletName': target.name,
      'newBalance': newBalance,
    };
  }
}

/// Mutation tool to transfer funds between wallets.
class TransferWalletTool extends SimoAgentTool<Map<String, dynamic>, Map<String, dynamic>> {
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
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double amount = (input['amount'] as num?)?.toDouble() ?? 0.0;
    if (amount <= 0) return {'isSuccess': false, 'error': 'Số tiền chuyển không hợp lệ'};

    final double fee = (input['fee'] as num?)?.toDouble() ?? 0.0;
    final note = input['note'] as String? ?? 'Chuyển tiền qua AI';
    final date = AgentDateHelper.parseDate(input['date'] as String?);

    List<Wallet> wallets = context.ref.read(walletProvider).value ?? [];
    if (wallets.isEmpty) {
      wallets = await context.ref.read(walletRepositoryProvider).getAllWallets();
    }
    if (wallets.length < 2) return {'isSuccess': false, 'error': 'Cần ít nhất 2 ví để thực hiện chuyển tiền'};

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

    return {
      'isSuccess': true,
      'sourceWalletId': srcId,
      'destinationWalletId': dstId,
      'amount': amount,
      'fee': fee,
    };
  }
}
