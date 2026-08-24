# Implementation Plan: Multi-Wallet & Transfer Management

**Branch**: `008-multi-wallet-management` | **Spec**: [specs/008-multi-wallet-management/spec.md](spec.md)

## Summary

Implement full Multi-Wallet and Transfer capability in SIMO. Allows users to segregate their funds across multiple accounts (Cash, Banks, E-wallets, Credit Cards, Savings), execute internal transfers with zero distortion to monthly expense analytics, view dedicated account statements, and preserve multi-wallet data across JSON backups and Excel workbooks.

## Phased Execution Strategy

- **Phase 1 (Localization & Data Models)**: Add EN/VI/ZH strings; build `Wallet` and `WalletTransfer` models.
- **Phase 2 (Database Migration v14 & Repository)**: Update `DatabaseHelper` schema v14 with auto-migration of legacy transactions into a default cash wallet; build `WalletRepository` with atomic transactions.
- **Phase 3 (State Management)**: Build `walletProvider` and `walletTransfersProvider`.
- **Phase 4 (UI - Wallets List & CRUD Modals)**: Build `WalletsScreen`, `WalletCard`, `WalletFormModal`, and `WalletTransferModal`.
- **Phase 5 (UI - Transaction Form & Dashboard Integration)**: Add wallet selector in transaction sheets; add Quick Access Hub shortcut.
- **Phase 6 (UI - Wallet Detail & Statement)**: Build `WalletDetailScreen` with dedicated statement timeline.
- **Phase 7 (Data Backup & Excel Export)**: Integrate with `BackupService` and `ExportService`.
- **Phase 8 (Tests & Quality Assurance)**: Write unit tests and verify `flutter analyze`.
