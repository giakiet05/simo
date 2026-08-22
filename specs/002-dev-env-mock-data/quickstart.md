# Quickstart & Verification Guide: Dev Environment & Mock Data

## Scenario 1: Verify Dev vs Production App Isolation
1. Build and install the debug app on the phone:
   ```bash
   flutter run
   ```
2. Verify on the device launcher that the app icon is named **Simo Dev** (package `com.simolab.simo.dev`).
3. If a production `Simo` APK is installed, verify both apps appear side-by-side without conflicts.

---

## Scenario 2: Generate Mock Data from Settings
1. Open the app on the phone.
2. Navigate to **Cài đặt (Settings)** tab.
3. Scroll to the **Dữ liệu & Phát triển (Data & Developer)** section.
4. Tap **Tạo dữ liệu mẫu (Mock Data)**.
5. Tap **Xác nhận (Confirm)** in the prompt.
6. Verify SnackBar displays "Đã tạo thành công dữ liệu mẫu!".
7. Navigate to:
   - **Dashboard**: Verify trend chart, monthly spending, and recent transactions display data from March to August 2026.
   - **Giao dịch (Transactions)**: Verify transactions are grouped by months (Tháng 8/2026, Tháng 7/2026, ... Tháng 3/2026).
   - **Thống kê (Statistics)**: Verify category pie charts and monthly comparisons show populated figures.
