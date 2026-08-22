# Quickstart Validation Guide: Data Export & Backup

This guide details the step-by-step validation scenarios to verify end-to-end functionality for Excel, CSV, PDF export, and JSON Backup & Restore.

## Prerequisites

1. Ensure the app has existing transaction data (e.g. use "Tạo dữ liệu mẫu" from Settings to generate 100+ transactions, categories, budgets, and loans).
2. Required packages added to `pubspec.yaml`:
   - `excel: ^4.0.6`
   - `csv: ^6.0.0`
   - `pdf: ^3.11.1`
   - `printing: ^5.13.2`
   - `share_plus: ^10.1.4`
   - `file_picker: ^8.1.7`

---

## Validation Scenario 1: Export to Excel (.xlsx)

1. Open **Cài đặt** (Settings) -> Tap **Xuất & Sao lưu dữ liệu** (Export & Backup).
2. Select time range (e.g., "Tháng này" or "Năm nay").
3. Tap **Xuất file Excel (.xlsx)**.
4. **Expected Outcome**:
   - Loading indicator appears while generating.
   - Native Share Sheet opens displaying `simo_export_YYYYMMDD_HHMMSS.xlsx`.
   - Opening the file in Excel / Google Sheets shows formatted sheets: `Giao dịch`, `Ngân sách`, `Sổ nợ`.
   - Vietnamese characters (e.g., "Ăn uống", "Cà phê sáng") render cleanly.

---

## Validation Scenario 2: Export to CSV (.csv)

1. Under the **Xuất báo cáo** tab, tap **Xuất file CSV (.csv)**.
2. **Expected Outcome**:
   - Native Share Sheet opens displaying `simo_transactions_YYYYMMDD.csv`.
   - File contains UTF-8 BOM (`\uFEFF`) and headers `Ngày,Giờ,Loại,Danh mục,Số tiền,Ghi chú,Công thức`.
   - Opening with Excel on Windows or macOS displays Vietnamese characters without encoding artifacts.

---

## Validation Scenario 3: Export Financial Report to PDF (.pdf)

1. Under the **Xuất báo cáo** tab, tap **Xuất báo cáo PDF (.pdf)**.
2. **Expected Outcome**:
   - Printable PDF document generated with styled header, summary cards, and transaction logs.
   - Native print/share sheet opens with valid PDF preview.

---

## Validation Scenario 4: Full JSON Backup & Restore (Clean Overwrite)

1. Switch to the **Sao lưu & Khôi phục** tab.
2. Tap **Tạo bản sao lưu (JSON)**.
3. Save/share the backup file `simo_backup_YYYYMMDD_HHMMSS.json`.
4. Go back to Settings -> **Đặt lại toàn bộ dữ liệu** (Reset All Data) to clear the database.
5. Verify Dashboard and Statistics are empty.
6. Open **Xuất & Sao lưu dữ liệu** -> Tap **Khôi phục từ file JSON**.
7. Pick the previously saved `.json` backup file.
8. Verify the summary dialog displays the exact count of transactions, categories, budgets, and loans.
9. Choose **Ghi đè toàn bộ**.
10. **Expected Outcome**:
    - App reloads and shows all previously backed up data on Dashboard, Categories, Budgets, and Statistics with 100% accuracy.

---

## Validation Scenario 5: Corrupted JSON File Handling

1. Create a dummy text file with invalid JSON content (e.g., `corrupted.json`).
2. Tap **Khôi phục từ file JSON** and select `corrupted.json`.
3. **Expected Outcome**:
   - App detects invalid schema/JSON syntax.
   - Shows an error snackbar/dialog explaining the file is invalid.
   - Existing database remains completely untouched.
