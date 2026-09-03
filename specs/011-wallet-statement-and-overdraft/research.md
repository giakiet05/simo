# Research & Technical Decisions: Wallet Statement Filtering & Overdraft Management

**Feature**: `011-wallet-statement-and-overdraft`
**Date**: 2026-09-03

## 1. Overdraft Transfer Policy

### Decision
Allow transfers where `amount + fee > sourceWallet.currentBalance`, but require explicit user confirmation before executing:
- Modal dialog:
  - Title: "Cảnh báo số dư" (Balance Warning)
  - Content: "Số dư ví nguồn không đủ, số dư sau khi chuyển sẽ bị âm. Bạn có chắc chắn muốn tiếp tục?"
  - Actions: [Hủy] (Cancel), [Tiếp tục chuyển] (Proceed)
- If user confirms, the repository proceeds with the transfer, and the source wallet's balance is recalculated into a negative number.

### Rationale
- Accommodates credit cards, overdraft accounts, and real-world cash flow lag.
- Keeps users in full control while preventing accidental overdrafts.

---

## 2. Statement Filtering Architecture in `WalletDetailScreen`

### Decision
Enhance `WalletDetailScreen` to stateful widget with two filters:
1. **Type Filter**: `all` (Tất cả), `income` (Thu nhập), `expense` (Chi tiêu), `transfer` (Chuyển khoản).
2. **Date Filter**: Month/Year selector (default: current month or All time toggle).
- Computed `filteredTransactions` and `filteredTransfers` determine:
  - Total Inflow in selected period
  - Total Outflow in selected period
  - Timeline list entries

### Rationale
- Matches user mental model from the Transactions screen.
- Allows fast reconciliation of monthly bank statements.

---

## 3. Dynamic Alert Theme in `WalletDetailScreen`

### Decision
If `wallet.currentBalance < 0`:
- Hero Card renders Crimson Red gradient (`#DC2626` to `#EF4444`).
- Balance text remains white on the red background.
- Detail badges and list items highlight deficit.

---

## 4. Fixed Width Amount Box in `WalletCard`

### Decision
Enforce a fixed width container (`width: 115`) on the right side of `WalletCard` wrapping `FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(...))`.
- The middle info column takes `Expanded` with `Text(wallet.name, maxLines: 2, softWrap: true)`.

### Rationale
- Guarantees predictable layout math and avoids content crowding on narrow mobile screens.
