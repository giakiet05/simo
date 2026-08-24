import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/wallet.dart';
import '../models/wallet_transfer.dart';
import '../repositories/wallet_repository.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});

class WalletNotifier extends StateNotifier<AsyncValue<List<Wallet>>> {
  final WalletRepository _repo;

  WalletNotifier(this._repo) : super(const AsyncValue.loading()) {
    loadWallets();
  }

  Future<void> loadWallets() async {
    try {
      state = const AsyncValue.loading();
      final wallets = await _repo.getAllWallets();
      state = AsyncValue.data(wallets);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> createWallet(Wallet wallet) async {
    await _repo.createWallet(wallet);
    await loadWallets();
  }

  Future<void> updateWallet(Wallet wallet) async {
    await _repo.updateWallet(wallet);
    await loadWallets();
  }

  Future<void> deleteWallet(String id) async {
    await _repo.deleteWallet(id);
    await loadWallets();
  }

  Future<void> setDefaultWallet(String id) async {
    await _repo.setDefaultWallet(id);
    await loadWallets();
  }

  Future<void> transferFunds({
    required String sourceWalletId,
    required String destinationWalletId,
    required double amount,
    double fee = 0.0,
    required DateTime transferDate,
    String? note,
  }) async {
    await _repo.transferFunds(
      sourceWalletId: sourceWalletId,
      destinationWalletId: destinationWalletId,
      amount: amount,
      fee: fee,
      transferDate: transferDate,
      note: note,
    );
    await loadWallets();
  }

  Future<void> recalculateAllBalances() async {
    final wallets = await _repo.getAllWallets();
    for (final w in wallets) {
      await _repo.recalculateWalletBalance(w.id);
    }
    await loadWallets();
  }
}

final walletProvider =
    StateNotifierProvider<WalletNotifier, AsyncValue<List<Wallet>>>((ref) {
  final repo = ref.watch(walletRepositoryProvider);
  return WalletNotifier(repo);
});

final defaultWalletProvider = Provider<Wallet?>((ref) {
  final walletsAsync = ref.watch(walletProvider);
  return walletsAsync.maybeWhen(
    data: (wallets) {
      try {
        return wallets.firstWhere((w) => w.isDefault);
      } catch (_) {
        return wallets.isNotEmpty ? wallets.first : null;
      }
    },
    orElse: () => null,
  );
});

final totalNetWorthProvider = Provider<double>((ref) {
  final walletsAsync = ref.watch(walletProvider);
  return walletsAsync.maybeWhen(
    data: (wallets) {
      return wallets
          .where((w) => !w.excludeFromTotal)
          .fold<double>(0.0, (sum, w) => sum + w.currentBalance);
    },
    orElse: () => 0.0,
  );
});

final walletTransfersProvider =
    FutureProvider.family<List<WalletTransfer>, String>((ref, walletId) async {
  final repo = ref.watch(walletRepositoryProvider);
  return await repo.getTransfersForWallet(walletId);
});

final allTransfersProvider = FutureProvider<List<WalletTransfer>>((ref) async {
  final repo = ref.watch(walletRepositoryProvider);
  return await repo.getAllTransfers();
});
