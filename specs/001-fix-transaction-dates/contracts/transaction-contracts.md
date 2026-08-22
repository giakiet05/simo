# Contracts: Transaction Form, Provider & UI Interfaces

## 1. UI Navigation & Form Contract (`TransactionFormScreen`)

### Input Parameters:
```dart
class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? editTransactionId;
  final String? editType;
  final String? editAmount;
  final String? editFormula;
  final String? editCategoryId;
  final String? editNote;
  final DateTime? editTransactionDate;
  final DateTime? editCreatedAt;
  final DateTime? editUpdatedAt;
  // OR accepting the Transaction object directly
  final Transaction? editTransaction;
}
```

### Form Initialization Contract:
- When `editTransaction` (or `editTransactionId`) is provided:
  - `item.transactionDate` MUST be initialized to `editTransaction?.transactionDate ?? editTransactionDate ?? editCreatedAt ?? DateTime.now()`
  - Date picker in form reflects this initialized date.

---

## 2. Service/Provider Contract (`TransactionNotifier`)

### `updateTransaction` Method Signature:
```dart
Future<void> updateTransaction(
  String id,
  String? categoryId,
  double amount,
  String type,
  String? note, {
  String? formula,
  String? recurringConfigId,
  DateTime? transactionDate,
})
```
- Behavior:
  - Preserves `createdAt` from original record.
  - Sets `updatedAt = DateTime.now()`.
  - Sets `transactionDate = transactionDate ?? existing.transactionDate ?? existing.createdAt`.
  - Persists to database helper.
  - Updates Riverpod state maintaining descending order by `transactionDate`.

---

## 3. UI Display Contract: Transaction Detail Modal

When user taps on a transaction or opens transaction details:
- Section 1: **Ngày giao dịch**: formatted date of `transactionDate`
- Section 2: **Ngày tạo**: formatted date & time of `createdAt`
- Section 3: **Ngày cập nhật**: formatted date & time of `updatedAt`
