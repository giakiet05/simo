import 'package:uuid/uuid.dart';
import '../agent_tool.dart';
import '../../../models/loan_contact.dart';
import '../../../models/loan_transaction.dart';
import '../../../models/wallet.dart';
import '../../../providers/loan_provider.dart';
import '../../../providers/transaction_provider.dart';
import '../../../providers/wallet_provider.dart';

/// Mutation tool to create a new debt or lending record.
class CreateLoanTool extends SimoAgentTool<Map<String, dynamic>, Map<String, dynamic>> {
  @override
  String get name => 'loan_create';

  @override
  String get description => 'Tạo khoản cho vay (người khác nợ) hoặc đi vay (mình nợ)';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['amount', 'contactName'],
    'properties': {
      'amount': {'type': 'number'},
      'loanType': {'type': 'string', 'enum': ['lent', 'borrowed']},
      'contactName': {'type': 'string'},
      'contactId': {'type': ['string', 'null']},
      'walletId': {'type': ['string', 'null']},
      'walletName': {'type': ['string', 'null']},
      'note': {'type': ['string', 'null']},
      'date': {'type': ['string', 'null']},
      'dueDate': {'type': ['string', 'null']},
    },
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double amount = (input['amount'] as num?)?.toDouble() ?? 0.0;
    if (amount <= 0) return {'isSuccess': false, 'error': 'Số tiền không hợp lệ'};

    final contactName = (input['contactName'] as String?)?.trim();
    if (contactName == null || contactName.isEmpty) {
      // Must not use generic placeholder defaults
      return {'isSuccess': false, 'error': 'Tên người liên hệ không được để trống'};
    }

    final loanType = input['loanType'] as String? ?? 'lent';
    final contactId = input['contactId'] as String?;
    final note = input['note'] as String? ?? '';
    final date = AgentDateHelper.parseDate(input['date'] as String?);

    List<LoanContact> loans = context.ref.read(loanProvider).value ?? [];
    if (loans.isEmpty) {
      loans = await context.ref.read(loanRepositoryProvider).getLoans();
    }

    LoanContact? existingContact;
    if (contactId != null) {
      existingContact = loans.where((l) => l.id == contactId).firstOrNull;
    }
    existingContact ??= loans.where(
      (l) => l.contactName.toLowerCase() == contactName.toLowerCase() && l.type == loanType,
    ).firstOrNull;

    String savedLoanId;
    if (existingContact != null) {
      savedLoanId = existingContact.id;
      final updated = existingContact.copyWith(
        remainingAmount: existingContact.remainingAmount + amount,
        totalAmount: existingContact.totalAmount + amount,
        status: 'active',
      );
      await context.ref.read(loanProvider.notifier).updateLoanContact(updated);

      final loanTx = LoanTransaction(
        id: const Uuid().v4(),
        loanId: existingContact.id,
        amount: amount,
        type: loanType,
        date: date,
        note: note.isNotEmpty ? note : 'Tạo thêm khoản nợ qua AI',
      );
      await context.ref.read(loanRepositoryProvider).insertLoanTransaction(loanTx);
    } else {
      final newContact = LoanContact(
        id: const Uuid().v4(),
        contactName: contactName,
        type: loanType,
        totalAmount: amount,
        remainingAmount: amount,
        status: 'active',
      );
      savedLoanId = newContact.id;
      await context.ref.read(loanProvider.notifier).addLoanContact(newContact);

      final loanTx = LoanTransaction(
        id: const Uuid().v4(),
        loanId: newContact.id,
        amount: amount,
        type: loanType,
        date: date,
        note: note.isNotEmpty ? note : 'Khởi tạo khoản nợ qua AI',
      );
      await context.ref.read(loanRepositoryProvider).insertLoanTransaction(loanTx);
    }

    // Invalidate transaction history for this contact
    context.ref.invalidate(loanTransactionsProvider(savedLoanId));

    // Resolve wallet
    List<Wallet> wallets = context.ref.read(walletProvider).value ?? [];
    if (wallets.isEmpty) {
      wallets = await context.ref.read(walletRepositoryProvider).getAllWallets();
    }
    final rawWalletId = input['walletId'] as String?;
    final rawWalletName = (input['walletName'] as String?) ?? (input['wallet'] as String?);

    Wallet? matchedWallet;
    if (rawWalletId != null && rawWalletId.isNotEmpty) {
      matchedWallet = wallets.where((w) => w.id == rawWalletId).firstOrNull;
    }
    if (matchedWallet == null && rawWalletName != null && rawWalletName.trim().isNotEmpty) {
      final query = rawWalletName.trim().toLowerCase();
      matchedWallet = wallets.where((w) => w.name.toLowerCase() == query).firstOrNull ??
          wallets.where((w) => w.name.toLowerCase().contains(query)).firstOrNull;
    }
    if (matchedWallet == null && rawWalletId != null && rawWalletId.trim().isNotEmpty) {
      final query = rawWalletId.trim().toLowerCase();
      matchedWallet = wallets.where((w) => w.name.toLowerCase() == query).firstOrNull ??
          wallets.where((w) => w.name.toLowerCase().contains(query)).firstOrNull;
    }
    matchedWallet ??= wallets.where((w) => w.isDefault).firstOrNull ?? (wallets.isNotEmpty ? wallets.first : null);
    final String? walletId = matchedWallet?.id;

    // Create corresponding financial transaction in global transactions ledger
    final isLent = loanType == 'lent';
    final mainTxType = isLent ? 'expense' : 'income';
    final categoryId = isLent ? 'sys_loan_lend' : 'sys_loan_borrow';
    final defaultPrefix = isLent ? 'Cho $contactName mượn' : 'Vay từ $contactName';
    final noteText = note.isNotEmpty ? '$defaultPrefix - $note' : defaultPrefix;

    await context.ref.read(transactionProvider.notifier).createTransactions([
      {
        'id': const Uuid().v4(),
        'categoryId': categoryId,
        'walletId': walletId,
        'amount': amount,
        'note': noteText,
        'type': mainTxType,
        'transactionDate': date,
      }
    ]);

    return {
      'isSuccess': true,
      'loanId': savedLoanId,
      'contactName': contactName,
      'loanType': loanType,
      'amount': amount,
      'walletId': walletId,
    };
  }
}

/// Mutation tool to update an existing loan contact, adjust amounts, or extend due dates.
class UpdateLoanTool extends SimoAgentTool<Map<String, dynamic>, Map<String, dynamic>> {
  @override
  String get name => 'loan_update';

  @override
  String get description => 'Sửa thông tin khoản nợ, dời ngày hẹn trả, hoặc điều chỉnh dư nợ';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'contactId': {'type': ['string', 'null']},
      'contactName': {'type': ['string', 'null']},
      'newName': {'type': ['string', 'null']},
      'totalAmount': {'type': ['number', 'null']},
      'remainingAmount': {'type': ['number', 'null']},
      'dueDate': {'type': ['string', 'null']},
      'note': {'type': ['string', 'null']},
    },
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    List<LoanContact> loans = context.ref.read(loanProvider).value ?? [];
    if (loans.isEmpty) {
      loans = await context.ref.read(loanRepositoryProvider).getLoans();
    }
    final contactId = input['contactId'] as String?;
    final contactName = input['contactName'] as String?;
    final newName = input['newName'] as String?;
    final totalAmount = (input['totalAmount'] as num?)?.toDouble();
    final remainingAmount = (input['remainingAmount'] as num?)?.toDouble();

    LoanContact? target;
    if (contactId != null && contactId.isNotEmpty) {
      target = loans.where((l) => l.id == contactId).firstOrNull;
    }
    if (target == null && contactName != null && contactName.isNotEmpty) {
      target = loans.where((l) => l.contactName.toLowerCase().contains(contactName.toLowerCase())).firstOrNull;
    }

    if (target == null) return {'isSuccess': false, 'error': 'Không tìm thấy thông tin khoản nợ'};

    final updated = target.copyWith(
      contactName: newName ?? target.contactName,
      totalAmount: totalAmount ?? target.totalAmount,
      remainingAmount: remainingAmount ?? target.remainingAmount,
    );

    await context.ref.read(loanProvider.notifier).updateLoanContact(updated);
    context.ref.invalidate(loanTransactionsProvider(target.id));

    return {
      'isSuccess': true,
      'loanId': target.id,
      'contactName': updated.contactName,
      'remainingAmount': updated.remainingAmount,
      'totalAmount': updated.totalAmount,
    };
  }
}

/// Mutation tool to delete an existing loan contact.
class DeleteLoanTool extends SimoAgentTool<Map<String, dynamic>, bool> {
  @override
  String get name => 'loan_delete';

  @override
  String get description => 'Xóa khoản nợ hoặc người liên hệ nợ';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'properties': {
      'contactId': {'type': ['string', 'null']},
      'contactName': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    List<LoanContact> loans = context.ref.read(loanProvider).value ?? [];
    if (loans.isEmpty) {
      loans = await context.ref.read(loanRepositoryProvider).getLoans();
    }
    final contactId = input['contactId'] as String?;
    final contactName = input['contactName'] as String?;

    LoanContact? target;
    if (contactId != null && contactId.isNotEmpty) {
      target = loans.where((l) => l.id == contactId).firstOrNull;
    }
    if (target == null && contactName != null && contactName.isNotEmpty) {
      target = loans.where((l) => l.contactName.toLowerCase().contains(contactName.toLowerCase())).firstOrNull;
    }

    if (target == null) return false;

    await context.ref.read(loanProvider.notifier).deleteLoanContact(target.id);
    return true;
  }
}

/// Mutation tool to repay or collect a debt.
class RepayLoanTool extends SimoAgentTool<Map<String, dynamic>, Map<String, dynamic>> {
  @override
  String get name => 'loan_repay';

  @override
  String get description => 'Ghi nhận trả nợ hoặc thu hồi nợ';

  @override
  Map<String, dynamic> get parametersSchema => {
    'type': 'object',
    'required': ['amount'],
    'properties': {
      'amount': {'type': 'number'},
      'repayType': {'type': 'string', 'enum': ['collect', 'repay']},
      'contactName': {'type': ['string', 'null']},
      'contactId': {'type': ['string', 'null']},
      'walletId': {'type': ['string', 'null']},
      'walletName': {'type': ['string', 'null']},
      'note': {'type': ['string', 'null']},
      'date': {'type': ['string', 'null']},
    },
  };

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double amount = (input['amount'] as num?)?.toDouble() ?? 0.0;
    if (amount <= 0) return {'isSuccess': false, 'error': 'Số tiền không hợp lệ'};

    final contactName = (input['contactName'] as String?)?.trim();
    final contactId = input['contactId'] as String?;
    final note = input['note'] as String? ?? '';
    final date = AgentDateHelper.parseDate(input['date'] as String?);

    List<LoanContact> loans = context.ref.read(loanProvider).value ?? [];
    if (loans.isEmpty) {
      loans = await context.ref.read(loanRepositoryProvider).getLoans();
    }

    LoanContact? contact;
    if (contactId != null) {
      contact = loans.where((l) => l.id == contactId).firstOrNull;
    }
    if (contact == null && contactName != null) {
      contact = loans.where(
        (l) => l.contactName.toLowerCase() == contactName.toLowerCase(),
      ).firstOrNull;
    }

    if (contact != null) {
      final double newRemaining = (contact.remainingAmount - amount).clamp(0.0, double.infinity);
      final updated = contact.copyWith(
        remainingAmount: newRemaining,
        status: newRemaining <= 0 ? 'settled' : 'active',
      );
      await context.ref.read(loanProvider.notifier).updateLoanContact(updated);

      final isBorrow = contact.type == 'borrowed';
      final actualRepayType = isBorrow ? 'repay' : 'collect';

      final loanTx = LoanTransaction(
        id: const Uuid().v4(),
        loanId: contact.id,
        amount: amount,
        type: actualRepayType,
        date: date,
        note: note.isNotEmpty ? note : (isBorrow ? 'Trả nợ qua AI' : 'Thu nợ qua AI'),
      );
      await context.ref.read(loanRepositoryProvider).insertLoanTransaction(loanTx);

      // Invalidate transaction history for this contact
      context.ref.invalidate(loanTransactionsProvider(contact.id));

      // Resolve wallet
      List<Wallet> wallets = context.ref.read(walletProvider).value ?? [];
      if (wallets.isEmpty) {
        wallets = await context.ref.read(walletRepositoryProvider).getAllWallets();
      }
      final rawWalletId = input['walletId'] as String?;
      final rawWalletName = (input['walletName'] as String?) ?? (input['wallet'] as String?);

      Wallet? matchedWallet;
      if (rawWalletId != null && rawWalletId.isNotEmpty) {
        matchedWallet = wallets.where((w) => w.id == rawWalletId).firstOrNull;
      }
      if (matchedWallet == null && rawWalletName != null && rawWalletName.trim().isNotEmpty) {
        final query = rawWalletName.trim().toLowerCase();
        matchedWallet = wallets.where((w) => w.name.toLowerCase() == query).firstOrNull ??
            wallets.where((w) => w.name.toLowerCase().contains(query)).firstOrNull;
      }
      if (matchedWallet == null && rawWalletId != null && rawWalletId.trim().isNotEmpty) {
        final query = rawWalletId.trim().toLowerCase();
        matchedWallet = wallets.where((w) => w.name.toLowerCase() == query).firstOrNull ??
            wallets.where((w) => w.name.toLowerCase().contains(query)).firstOrNull;
      }
      matchedWallet ??= wallets.where((w) => w.isDefault).firstOrNull ?? (wallets.isNotEmpty ? wallets.first : null);
      final String? walletId = matchedWallet?.id;

      // Create corresponding financial transaction in global transactions ledger
      final mainTxType = isBorrow ? 'expense' : 'income';
      final categoryId = isBorrow ? 'sys_loan_repay' : 'sys_loan_collect';
      final defaultPrefix = isBorrow ? 'Trả cho ${contact.contactName}' : 'Thu từ ${contact.contactName}';
      final noteText = note.isNotEmpty ? '$defaultPrefix - $note' : defaultPrefix;

      await context.ref.read(transactionProvider.notifier).createTransactions([
        {
          'id': const Uuid().v4(),
          'categoryId': categoryId,
          'walletId': walletId,
          'amount': amount,
          'note': noteText,
          'type': mainTxType,
          'transactionDate': date,
        }
      ]);

      return {
        'isSuccess': true,
        'loanId': contact.id,
        'contactName': contact.contactName,
        'repayType': actualRepayType,
        'amount': amount,
        'remainingAmount': newRemaining,
        'status': updated.status,
      };
    }

    return {'isSuccess': false, 'error': 'Không tìm thấy khoản nợ tương ứng'};
  }
}
