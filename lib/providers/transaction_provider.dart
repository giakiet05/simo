import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepository();
});

class TransactionNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repository;

  TransactionNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? type,
    String? keyword,
    double? minAmount,
    double? maxAmount,
  }) async {
    state = const AsyncValue.loading();
    try {
      final transactions = await _repository.getAll(
        startDate: startDate,
        endDate: endDate,
        categoryId: categoryId,
        type: type,
        keyword: keyword,
        minAmount: minAmount,
        maxAmount: maxAmount,
      );
      state = AsyncValue.data(transactions);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  Future<void> createTransactions(
      List<Map<String, dynamic>> transactionData) async {
    try {
      await _repository.createMultiple(transactionData);
      await loadTransactions();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateTransaction(
    String id, {
    String? categoryId,
    double? amount,
    String? formula,
    String? note,
    String? type,
  }) async {
    try {
      await _repository.update(
        id,
        categoryId: categoryId,
        amount: amount,
        formula: formula,
        note: note,
        type: type,
      );
      await loadTransactions();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteTransactions(List<String> ids) async {
    try {
      await _repository.deleteMultiple(ids);
      await loadTransactions();
    } catch (error) {
      rethrow;
    }
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier,
    AsyncValue<List<Transaction>>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionNotifier(repository);
});
