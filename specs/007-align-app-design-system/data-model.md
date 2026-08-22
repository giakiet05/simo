# Data Model: UI Refactoring Targets

**Feature**: `007-align-app-design-system`

## Refactoring Target Matrix

| Target File | Current Inconsistency | Standard Design System Rule |
|-------------|----------------------|-----------------------------|
| `lib/screens/recurring_screen.dart` | `inversePrimary` AppBar, bulky `TextButton.icon`, `.withOpacity` | `elevation: 0`, standard `IconButton(icon: Icon(Icons.add))`, `.withValues(alpha: ...)`, scrollable filter chips |
| `lib/screens/loan_screen.dart` | `inversePrimary` AppBar, unscrollable filter chips, `.withOpacity` | `elevation: 0`, `SingleChildScrollView(scrollDirection: Axis.horizontal)`, `.withValues(alpha: ...)` |
| `lib/screens/loan_detail_screen.dart` | `.withOpacity` calls | `.withValues(alpha: ...)` |
| `lib/screens/category_screen.dart` | `inversePrimary` AppBar, `.withOpacity` | `elevation: 0`, `IconButton(icon: Icon(Icons.add))`, `.withValues(alpha: ...)` |
| `lib/screens/category_budget_screen.dart` | Modal uses `Radius.circular(16)` | `Radius.circular(20)` modal top radius |
| `lib/screens/statistics_screen.dart` | Custom chip row wrapping | `SingleChildScrollView(scrollDirection: Axis.horizontal)` |
| `lib/screens/settings_screen.dart` | `.withOpacity` on borders and dividers | `.withValues(alpha: 0.15 - 0.20)` |
| `lib/screens/dashboard_screen.dart` | `.withOpacity` calls | `.withValues(alpha: ...)` |
| `lib/screens/transaction_form_screen.dart` | `.withOpacity` calls | `.withValues(alpha: ...)` |
| `lib/widgets/loan_transaction_modal.dart` | `.withOpacity` calls | `.withValues(alpha: ...)` |
| `lib/widgets/icon_picker_dialog.dart` | `.withOpacity` calls | `.withValues(alpha: ...)` |
| `lib/widgets/voice_record_sheet.dart` | `.withOpacity` calls | `.withValues(alpha: ...)` |
