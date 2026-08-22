# Quickstart & Verification Guide: Multi-Month Budgets & Mock Data

**Feature**: [Multi-Month Budget Management & Rich Mock Data](spec.md)  
**Date**: 2026-08-21  

---

## Prerequisites

1. Ensure the app compiles and connects to an emulator or physical device.
2. Flutter version 3.27+ with Dart 3.6+.

---

## Verification Scenarios

### Scenario 1: Generate Multi-Month Mock Budgets
1. Open the app -> Navigate to **Cài đặt** -> **Dữ liệu & Thử nghiệm** -> Tap **Tạo dữ liệu mẫu**.
2. Confirm the generation dialog.
3. Open the **Danh mục & Ngân sách** screen (or tap on the Budget section).
4. Verify that:
   - All 6 months from **Tháng 3/2026** to **Tháng 8/2026** have total budgets configured (e.g. 25,000,000 - 30,000,000 VND).
   - Each month shows all 5 expense categories (`Ăn uống`, `Đi lại`, `Mua sắm`, `Hóa đơn & Tiện ích`, `Giải trí & Du lịch`) with assigned budget limits.
   - Varied spending progress states are clearly visible (e.g. green normal, orange near limit, red over budget).

---

### Scenario 2: Navigate Historical Months & Edit Budgets
1. In the **Danh mục & Ngân sách** screen, tap the `<` arrow to go back to **Tháng 4/2026**.
2. Tap on the total budget card to change the budget from 25,000,000 VND to 28,000,000 VND.
3. Tap Save.
4. Navigate to **Tháng 5/2026** and verify that Month 5's budget is unaffected.
5. Navigate back to **Tháng 4/2026** and verify that 28,000,000 VND persists accurately.

---

### Scenario 3: Synchronized View in Statistics Screen
1. Navigate to the **Thống kê** (Statistics) tab.
2. Select **Tháng 6/2026** in the category month picker.
3. Verify that the category budget progress bars match the budget limits and transaction amounts for June 2026.

---

### Scenario 4: Automated Tests Execution
Run the unit and repository test suites:
```bash
flutter test test/unit/monthly_budget_test.dart
flutter test test/unit/mock_data_generator_test.dart
```
Ensure all tests pass with 0 errors.
