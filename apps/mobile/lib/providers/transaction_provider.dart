import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction.dart';
import '../repositories/transaction_repository.dart';
import 'wallet_provider.dart';
import 'sync_provider.dart';

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
      _ref.read(syncProvider.notifier).triggerDebouncedSync();
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
      _ref.read(syncProvider.notifier).triggerDebouncedSync();
    } catch (error) {
      rethrow;
    }
  }

  Future<void> deleteTransactions(List<String> ids) async {
    try {
      await _repository.deleteMultiple(ids);
      await loadTransactions();
      _ref.read(walletProvider.notifier).loadWallets();
      _ref.read(syncProvider.notifier).triggerDebouncedSync();
    } catch (error) {
      rethrow;
    }
  }

  /// Bulk updates the wallet for given transaction IDs.
  ///
  /// @param ids List of transaction IDs.
  /// @param walletId Target wallet ID.
  Future<void> updateTransactionsWallet(List<String> ids, String walletId) async {
    try {
      await _repository.updateWalletMultiple(ids, walletId);
      await loadTransactions();
      _ref.read(walletProvider.notifier).loadWallets();
      _ref.read(syncProvider.notifier).triggerDebouncedSync();
    } catch (error) {
      rethrow;
    }
  }

  /// Bulk updates the category for given transaction IDs.
  ///
  /// @param ids List of transaction IDs.
  /// @param categoryId Target category ID (or null).
  Future<void> updateTransactionsCategory(List<String> ids, String? categoryId) async {
    try {
      await _repository.updateCategoryMultiple(ids, categoryId);
      await loadTransactions();
      _ref.read(syncProvider.notifier).triggerDebouncedSync();
    } catch (error) {
      rethrow;
    }
  }

  /// Bulk updates the date for given transaction IDs preserving time components.
  ///
  /// @param ids List of transaction IDs.
  /// @param date Target date.
  Future<void> updateTransactionsDate(List<String> ids, DateTime date) async {
    try {
      await _repository.updateDateMultiple(ids, date);
      await loadTransactions();
      _ref.read(syncProvider.notifier).triggerDebouncedSync();
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
