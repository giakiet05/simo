# Quickstart & Validation Guide: Wallet Statement Filtering & Overdraft Management

**Feature**: `011-wallet-statement-and-overdraft`
**Date**: 2026-09-03

## 1. Validation Scenarios

### Scenario 1: Overdraft Transfer Confirmation
1. Select a wallet with 100,000 VND.
2. Transfer 500,000 VND to another wallet.
3. Observe confirmation popup: "Cảnh báo số dư - Số dư ví nguồn không đủ...".
4. Tap "Tiếp tục chuyển".
5. Verify source wallet is now `-400,000 VND` with red alert gradient.

### Scenario 2: Statement Filtering by Type & Time
1. Open Wallet Detail screen.
2. Tap "Chi tiêu" chip -> verify only expense transactions are shown.
3. Tap "Chuyển tiền" chip -> verify only transfer-in and transfer-out entries are shown.
4. Select a specific month -> verify inflow, outflow, and timeline entries match that month.

### Scenario 3: Negative Balance Alert Theme
1. Open detail view for wallet with negative balance.
2. Verify top Hero Card background is Crimson Red.
