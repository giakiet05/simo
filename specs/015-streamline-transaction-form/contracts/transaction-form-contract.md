# UI & Component Contracts: Streamline Transaction Form

## 1. Screen Invocation Contract

```dart
class TransactionFormScreen extends ConsumerStatefulWidget {
  /// Unique identifier of the transaction if editing. Null if creating new.
  final String? editTransactionId;

  /// Initial transaction type ('expense' or 'income'). Defaults to 'expense'.
  final String? editType;

  /// Initial raw amount or formula string.
  final String? editAmount;

  /// Mathematical expression string if previously entered via formula.
  final String? editFormula;

  /// ID of the initial category.
  final String? editCategoryId;

  /// ID of the initial wallet. Defaults to default wallet if null.
  final String? editWalletId;

  /// Initial optional note string.
  final String? editNote;

  /// Explicit transaction date.
  final DateTime? editTransactionDate;

  /// Original record creation date (for fallback).
  final DateTime? editCreatedAt;

  const TransactionFormScreen({
    super.key,
    this.editTransactionId,
    this.editType,
    this.editAmount,
    this.editFormula,
    this.editCategoryId,
    this.editWalletId,
    this.editNote,
    this.editTransactionDate,
    this.editCreatedAt,
  });
}
```

---

## 2. CategoryGridPicker Contract

```dart
/// Renders an ergonomic 4-column visual grid of categories with icons and localized titles.
class CategoryGridPicker extends StatelessWidget {
  /// The filtered list of categories matching current transaction type.
  final List<Category> categories;

  /// Currently selected category ID.
  final String? selectedCategoryId;

  /// Callback when a category icon tile is tapped.
  final ValueChanged<Category> onCategorySelected;

  const CategoryGridPicker({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
  });
}
```

---

## 3. CustomNumPad Integration Contract

```dart
/// Preserved calculator-style numeric keypad with operators, 000, and live evaluation.
class CustomNumPad extends StatelessWidget {
  /// Controller bound to the active amount/formula text field.
  final TextEditingController amountController;

  /// Controller bound to the note text field (optional).
  final TextEditingController? noteController;

  /// Optional callback triggered when the user presses the checkmark/save/done button.
  final VoidCallback? onDone;

  const CustomNumPad({
    super.key,
    required this.amountController,
    this.noteController,
    this.onDone,
  });
}
```

---

## 4. WalletQuickPicker & DateQuickChips Contract

```dart
/// Compact chip button for wallet selection with icon, color indicator, and balance preview.
class WalletChipSelector extends StatelessWidget {
  final List<Wallet> wallets;
  final String? selectedWalletId;
  final ValueChanged<Wallet> onWalletChanged;
  
  const WalletChipSelector({
    super.key,
    required this.wallets,
    required this.selectedWalletId,
    required this.onWalletChanged,
  });
}

/// Quick date selection bar with chips for Today, Yesterday, and Calendar picker.
class DateQuickChipsBar extends StatelessWidget {
  final DateTime selectedDate;
  final DateTime? originalDate;
  final ValueChanged<DateTime> onDateChanged;

  const DateQuickChipsBar({
    super.key,
    required this.selectedDate,
    this.originalDate,
    required this.onDateChanged,
  });
}
```
