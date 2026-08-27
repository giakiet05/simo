# Quickstart & Verification Guide: Dashboard & Wallet Integration

**Feature**: `009-dashboard-wallet-integration`
**Date**: 2026-08-26

## 1. Prerequisites
- SQLite database on v14 schema with `wallets` and `wallet_transfers` tables.
- Flutter SDK 3.x with Riverpod.

## 2. Validation Scenarios

### Scenario 1: Total Net Worth & Privacy Masking
1. Launch the app and open Dashboard.
2. Verify the top Hero card displays **"Tổng tài sản"** with the sum of all included wallets (e.g. `25.500.000 ₫`).
3. Tap the eye icon on the Net Worth card.
4. Verify all balance numbers in both the Net Worth card and the mini-wallet carousel change to `••••••`.
5. Tap the eye icon again; verify numbers are restored.

### Scenario 2: Quick Transfer from Dashboard
1. On the Net Worth card, tap **[Chuyển tiền]**.
2. Verify the `WalletTransferModal` opens directly.
3. Select Source: Vietcombank, Destination: Tiền mặt, Amount: 1.000.000 ₫. Tap Chuyển.
4. Verify modal closes, Net Worth remains unchanged (25.5M), while Vietcombank decreases by 1M and Tiền mặt increases by 1M in the mini-wallet carousel.

### Scenario 3: Mini-Wallet Tap & Detail Statement
1. In the mini-wallet carousel, tap on the **"Tiền mặt"** card.
2. Verify app navigates smoothly to `WalletDetailScreen` for "Tiền mặt".
3. Verify the timeline shows the recent incoming 1M transfer and historical transactions for that wallet.

### Scenario 4: Monthly Cash Flow vs Total Net Worth Independence
1. In Dashboard, scroll down to Tier 2 and check the **"Dòng tiền tháng"** (or **"Thặng dư tháng"**) card.
2. Switch month dropdown from August 2026 to July 2026.
3. Verify:
   - **Top Net Worth card & Mini-wallet carousel**: REMAIN CONSTANT (reflecting current real wealth).
   - **Monthly Cashflow & Income/Expense**: DYNAMICALLY CHANGE to reflect July 2026 transactions.

### Scenario 5: Full Vietnamese Localization
1. Set language to Vietnamese.
2. Verify no untranslated English strings exist across Dashboard, Wallet Cards, and Modals.

## 3. Automated Test Commands

```bash
# Run all unit tests
flutter test --concurrency=1 test/unit/

# Run static analysis
flutter analyze lib/
```
