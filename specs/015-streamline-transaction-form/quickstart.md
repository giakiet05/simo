# Quickstart & Validation Guide: Streamline Transaction Form

## Prerequisites
- Flutter SDK installed and environment healthy.
- App running either on emulator, physical device, or via automated widget tests.

---

## Validation Scenarios

### Scenario 1: Quick Expense Creation with Calculator
1. Open the app and navigate to Transactions tab.
2. Tap the `+` FloatingActionButton.
3. Observe the form:
   - Type is defaulted to "Expense" (red highlight).
   - Category grid shows expense categories (Food, Transportation, Shopping, etc.).
   - Amount field is active.
4. Using the custom keypad:
   - Tap `50`, tap `000`, tap `+`, tap `25`, tap `000`.
   - Observe live formula `50,000 + 25,000` and evaluated amount `75,000 ₫`.
5. Tap the "Food & Dining" category icon in the grid.
6. Tap "Save".
7. Verify transaction is recorded as `-75,000 ₫` under Food category in the list.

### Scenario 2: Switch to Income with Dynamic Category Grid
1. Tap `+` to open form.
2. Tap the "Income" tab.
3. Observe:
   - Segment changes to green.
   - Category grid instantly re-filters to show Income categories (Salary, Bonus, Other Income).
4. Enter `10` + `000` + `000` (10,000,000).
5. Select "Salary" category and choose "Bank" wallet.
6. Tap "Save".
7. Verify transaction is added as `+10,000,000 ₫` and Bank wallet balance increases accordingly.

### Scenario 3: Edit Mode Context Preservation
1. From the transaction list, tap any existing transaction to open detail sheet.
2. Tap the Edit button.
3. Observe:
   - AppBar shows "Edit Transaction".
   - Amount, Category, Wallet, and Date are accurately pre-filled.
   - "Original Date" chip is available if date is changed.
4. Change the category and tap "Save".
5. Verify updated category is reflected without creating a duplicate record.

### Scenario 4: Continuous Logging ("Save & Add Another")
1. Open form in Add mode.
2. Enter `30,000`, select Category "Coffee", Wallet "Cash".
3. Tap "Save & Add Another" (or checkmark shortcut).
4. Verify:
   - First transaction is committed to DB.
   - Form remains open.
   - Amount is reset to empty.
   - Wallet remains "Cash" and Date remains current.
5. Enter second transaction `20,000`, Category "Snack", and tap "Save".
6. Verify both transactions exist in history.

---

## Automated Verification Commands

```bash
# 1. Run unit & widget tests
flutter test test/widget_transaction_detail_test.dart test/unit/transaction_bulk_actions_test.dart

# 2. Run static analysis
flutter analyze lib/screens/transaction_form_screen.dart lib/widgets/custom_num_pad.dart

# 3. Launch on physical device
flutter run
```
