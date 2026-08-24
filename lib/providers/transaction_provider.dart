import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import 'wallet_provider.dart';

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  final walletRepo = ref.watch(walletRepositoryProvider);
  return TransactionRepository(walletRepo: walletRepo);
});

class TransactionNotifier extends StateNotifier<AsyncValue<List<Transaction>>> {
  final TransactionRepository _repository;
  final Ref _ref;

  TransactionNotifier(this._repository, this._ref)
      : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  Future<void> loadTransactions({
    DateTime? startDate,
    DateTime? endDate,
    String? categoryId,
    String? walletId,
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
        walletId: walletId,
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
      _ref.read(walletProvider.notifier).loadWallets();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> updateTransaction(
    String id, {
    String? categoryId,
    String? walletId,
    double? amount,
    String? formula,
    String? note,
    String? type,
    DateTime? transactionDate,
  }) async {
    try {
      await _repository.update(
        id,
        categoryId: categoryId,
        walletId: walletId,
        amount: amount,
        formula: formula,
        note: note,
        type: type,
        transactionDate: transactionDate,
      );
      await loadTransactions();
      _ref.read(walletProvider.notifier).loadWallets();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteTransactions(List<String> ids) async {
    try {
      await _repository.deleteMultiple(ids);
      await loadTransactions();
      _ref.read(walletProvider.notifier).loadWallets();
    } catch (error) {
      rethrow;
    }
  }
}

final transactionProvider = StateNotifierProvider<TransactionNotifier,
    AsyncValue<List<Transaction>>>((ref) {
  final repository = ref.watch(transactionRepositoryProvider);
  return TransactionNotifier(repository, ref);
});

// Alias for convenience
final transactionNotifierProvider = transactionProvider;
