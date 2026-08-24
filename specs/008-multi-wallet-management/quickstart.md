# Quickstart & Integration Validation: Multi-Wallet & Transfers

**Feature**: `008-multi-wallet-management`

## End-to-End Validation Scenarios

### Scenario 1: Wallet Creation & Starting Balance
1. Open Wallets screen via Quick Access Hub.
2. Tap `+` action button in AppBar.
3. Fill name: "Techcombank", type: "bank", initial balance: "10,000,000", color: Red, icon: "account_balance".
4. Save. Verify "Techcombank" appears with 10,000,000 VND and Total Net Worth increases by 10,000,000 VND.

### Scenario 2: Transaction Attached to Wallet
1. Create an Expense of 200,000 VND for "Ăn uống", select wallet: "Techcombank".
2. Save transaction.
3. Open Wallets screen: Verify "Techcombank" balance is now 9,800,000 VND.

### Scenario 3: Internal Transfer Between Wallets
1. Tap "Chuyển tiền" (Transfer).
2. Source: "Techcombank", Destination: "Ví tiền mặt", Amount: 1,000,000 VND, Fee: 1,100 VND.
3. Submit.
4. Verify Techcombank is now 8,798,900 VND and Ví tiền mặt increases by 1,000,000 VND.
5. Verify Statistics / Budget Screen does NOT count 1,000,000 VND as expense.

### Scenario 4: Backup & Restore
1. Export JSON backup snapshot.
2. Clear all data.
3. Restore from backup.
4. Verify all wallets, transfers, and balances are 100% recovered.
