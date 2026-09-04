# UI Contracts: Features Hub Screen (Màn hình Chức năng)

**Feature**: `013-features-hub-tab`
**Date**: 2026-09-03

## 1. Screen Contract

```dart
class FeaturesScreen extends ConsumerWidget {
  const FeaturesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref);
}
```

## 2. Navigation Contract in HomeScreen

```dart
// lib/screens/home_screen.dart
final List<Widget> _screens = [
  const DashboardScreen(),
  TransactionScreen(key: transactionScreenKey),
  const FeaturesScreen(), // Replaces LoanScreen
  const SettingsScreen(),
];

// BottomNavigationBar items:
BottomNavigationBarItem(
  icon: const Icon(Icons.grid_view_rounded),
  label: l10n.locale == 'vi' ? 'Chức năng' : 'Features',
),
```

## 3. Localization Keys Contract

```dart
// lib/utils/localization.dart
// New getters:
String get featuresHub; // vi: "Chức năng", en: "Features"
String get sectionCashflowAndAssets; // vi: "Dòng tiền & Tài sản", en: "Cashflow & Accounts"
String get sectionFinancialPlanning; // vi: "Kế hoạch Tài chính", en: "Financial Planning"
String get sectionDebtsAndAnalytics; // vi: "Đối soát & Thống kê", en: "Debts & Analytics"
String get sectionDataAndUtilities; // vi: "Dữ liệu & Tiện ích", en: "Data & Utilities"
```
