# Contract: Wallet & Transfer Repository Service

**Feature**: `008-multi-wallet-management`

## WalletRepository Interface Contract

```dart
abstract class IWalletRepository {
  Future<List<Wallet>> getAllWallets();
  Future<Wallet?> getWalletById(String id);
  Future<Wallet?> getDefaultWallet();
  Future<void> createWallet(Wallet wallet);
  Future<void> updateWallet(Wallet wallet);
  Future<void> deleteWallet(String id);
  Future<void> setDefaultWallet(String id);
  
  // Transfers
  Future<void> transferFunds({
    required String sourceWalletId,
    required String destinationWalletId,
    required double amount,
    double fee = 0.0,
    required DateTime transferDate,
    String? note,
  });
  
  Future<List<WalletTransfer>> getTransfersForWallet(String walletId);
  Future<List<WalletTransfer>> getAllTransfers();
  Future<void> deleteTransfer(String transferId);
  
  // Balance recalculation helper
  Future<void> recalculateWalletBalance(String walletId);
}
```
