import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/loan_contact.dart';
import '../models/loan_transaction.dart';
import '../repositories/loan_repository.dart';

final loanRepositoryProvider = Provider<LoanRepository>((ref) {
  return LoanRepository();
});

final loanProvider = StateNotifierProvider<LoanNotifier, AsyncValue<List<LoanContact>>>((ref) {
  final repository = ref.watch(loanRepositoryProvider);
  return LoanNotifier(repository);
});

class LoanNotifier extends StateNotifier<AsyncValue<List<LoanContact>>> {
  final LoanRepository _repository;

  LoanNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadLoans();
  }

  Future<void> loadLoans() async {
    try {
      state = const AsyncValue.loading();
      final loans = await _repository.getLoans();
      state = AsyncValue.data(loans);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> addLoanContact(LoanContact loan) async {
    try {
      await _repository.insertLoanContact(loan);
      await loadLoans();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateLoanContact(LoanContact loan) async {
    try {
      await _repository.updateLoanContact(loan);
      await loadLoans();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> deleteLoanContact(String id) async {
    try {
      await _repository.deleteLoanContact(id);
      await loadLoans();
    } catch (e) {
      rethrow;
    }
  }
}

// A family provider to watch a specific loan's transactions
final loanTransactionsProvider = FutureProvider.family<List<LoanTransaction>, String>((ref, loanId) async {
  final repository = ref.watch(loanRepositoryProvider);
  return await repository.getLoanTransactions(loanId);
});
