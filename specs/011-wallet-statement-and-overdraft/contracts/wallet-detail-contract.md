# UI Contracts: Wallet Statement Filtering & Overdraft Management

**Feature**: `011-wallet-statement-and-overdraft`
**Date**: 2026-09-03

## 1. `WalletDetailScreen` Interface Contract

```dart
class WalletDetailScreen extends ConsumerStatefulWidget {
  final String walletId;

  const WalletDetailScreen({
    super.key,
    required this.walletId,
  });
}
```

## 2. Localization Additions in `localization.dart`

| Key | vi | en | zh |
| :--- | :--- | :--- | :--- |
| `overdraft_warning_title` | `Cảnh báo số dư` | `Balance Warning` | `余额警告` |
| `overdraft_warning_message` | `Số dư ví nguồn không đủ. Ví sẽ bị âm sau khi chuyển. Bạn có chắc chắn muốn tiếp tục?` | `Source wallet balance is insufficient. Balance will become negative after transfer. Do you want to proceed?` | `源钱包余额不足。转账后余额将变为负数。您确定要继续吗？` |
| `proceed_transfer` | `Tiếp tục chuyển` | `Proceed Transfer` | `继续转账` |
| `filter_all` | `Tất cả` | `All` | `全部` |
| `filter_income` | `Thu nhập` | `Income` | `收入` |
| `filter_expense` | `Chi tiêu` | `Expense` | `支出` |
| `filter_transfers` | `Chuyển tiền` | `Transfers` | `转账` |
| `all_time` | `Tất cả thời gian` | `All time` | `所有时间` |
| `this_month` | `Tháng này` | `This month` | `本月` |
