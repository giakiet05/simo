import 'package:uuid/uuid.dart';
import '../agent_tool.dart';
import '../../../models/loan_contact.dart';
import '../../../models/loan_transaction.dart';
import '../../../providers/loan_provider.dart';

/// Mutation tool to create a new debt or lending record.
class CreateLoanTool extends SimoAgentTool<Map<String, dynamic>, bool> {
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
      'note': {'type': ['string', 'null']},
      'date': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double amount = (input['amount'] as num?)?.toDouble() ?? 0.0;
    if (amount <= 0) return false;

    final loanType = input['loanType'] as String? ?? 'lent';
    final contactName = (input['contactName'] as String?)?.trim() ?? 'Người quen';
    final contactId = input['contactId'] as String?;
    final note = input['note'] as String? ?? '';
    final dateStr = input['date'] as String?;
    final date = dateStr != null ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now();

    final loans = context.ref.read(loanProvider).value ?? [];

    LoanContact? existingContact;
    if (contactId != null) {
      existingContact = loans.where((l) => l.id == contactId).firstOrNull;
    }
    existingContact ??= loans.where(
      (l) => l.contactName.toLowerCase() == contactName.toLowerCase() && l.type == loanType,
    ).firstOrNull;

    if (existingContact != null) {
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

    return true;
  }
}

/// Mutation tool to repay or collect a debt.
class RepayLoanTool extends SimoAgentTool<Map<String, dynamic>, bool> {
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
      'note': {'type': ['string', 'null']},
      'date': {'type': ['string', 'null']},
    },
  };

  @override
  Future<bool> execute(Map<String, dynamic> input, AgentExecutionContext context) async {
    final double amount = (input['amount'] as num?)?.toDouble() ?? 0.0;
    if (amount <= 0) return false;

    final repayType = input['repayType'] as String? ?? 'repay';
    final contactName = (input['contactName'] as String?)?.trim();
    final contactId = input['contactId'] as String?;
    final note = input['note'] as String? ?? '';
    final dateStr = input['date'] as String?;
    final date = dateStr != null ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now();

    final loans = context.ref.read(loanProvider).value ?? [];

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

      final loanTx = LoanTransaction(
        id: const Uuid().v4(),
        loanId: contact.id,
        amount: amount,
        type: repayType,
        date: date,
        note: note.isNotEmpty ? note : (repayType == 'collect' ? 'Thu nợ qua AI' : 'Trả nợ qua AI'),
      );
      await context.ref.read(loanRepositoryProvider).insertLoanTransaction(loanTx);
      return true;
    }

    return false;
  }
}
