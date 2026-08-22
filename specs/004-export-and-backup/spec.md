# Feature Specification: Data Export & Backup (Excel, CSV, PDF, JSON Import/Export)

**Feature Branch**: `004-export-and-backup`

**Created**: 2026-08-22

**Status**: Draft

**Input**: User description: "lên kế hoạch làm kế hoạch xuất excel và backup, xuất nhiều dạng càng tốt nhé, thực ra hỗ trợ excel, csv, pdf và json là được, json sẽ dùng để import vào lại"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Full Data Backup & Restore via JSON (Priority: P1)

As a user who wants to safeguard my financial data or migrate to a new device, I want to export my entire app database to a structured JSON file and restore/import it whenever needed, so that I never lose my transaction history, category settings, budgets, loans, or recurring schedules.

**Why this priority**: Data safety and portability are fundamental. A reliable JSON backup & restore mechanism guarantees zero data loss and allows seamless data transfer between devices.

**Independent Test**: Can be fully tested by creating mock/live records (transactions, categories, loans, monthly budgets, recurring configs), exporting a JSON backup file, modifying/resetting the app data, importing the JSON file back, and verifying that all records and relationships are accurately restored.

**Acceptance Scenarios**:

1. **Given** the app contains transactions, categories, budgets, loans, and recurring configs, **When** the user selects "Sao lưu dữ liệu (JSON)" in Settings/Export screen, **Then** a structured `.json` backup file containing all entities with schema version and timestamp metadata is generated and the system share/save dialog is presented.
2. **Given** a valid `.json` backup file, **When** the user selects "Khôi phục dữ liệu từ JSON" and picks the file, **Then** the app validates the file format, displays a summary dialog showing record counts (e.g. 120 transactions, 10 categories, 3 loans), and asks the user to choose between "Ghi đè toàn bộ" (Overwrite) or "Gộp dữ liệu" (Merge).
3. **Given** an invalid or corrupted file (or incompatible JSON structure), **When** the user attempts to import it, **Then** the app aborts the operation safely with a clear, user-friendly error message without corrupting the existing database.

---

### User Story 2 - Export Transactions to Excel (.xlsx) (Priority: P2)

As a user who wants to analyze my personal finances in detail or review them on a computer, I want to export my transactions and financial summaries into a well-formatted Excel (.xlsx) workbook, so that I can filter, formula-check, and archive my spending records in spreadsheet software.

**Why this priority**: Excel is the most popular tool for deep personal financial analysis. Multi-sheet support allows organizing transactions, category breakdowns, budgets, and loans cleanly.

**Independent Test**: Can be fully tested by filtering a date range (e.g., this month, custom range, or all-time), tapping "Xuất Excel (.xlsx)", opening the resulting `.xlsx` file, and verifying that headers, amounts, dates, notes, category names, and summary totals match the in-app data.

**Acceptance Scenarios**:

1. **Given** a collection of transactions across multiple months, **When** the user chooses "Xuất Excel (.xlsx)" and selects a time range (Tháng này, Năm nay, Tùy chọn, hoặc Toàn bộ), **Then** an `.xlsx` file is generated with formatted header columns (Ngày, Giờ, Loại, Danh mục, Số tiền, Ghi chú, Công thức tính), proper number formatting, and a dedicated summary row for total income, total expense, and balance.
2. **Given** active category budgets and loan contacts, **When** exporting Excel, **Then** the workbook includes distinct sheets (e.g., "Giao dịch", "Ngân sách danh mục", "Sổ nợ") for a comprehensive financial view.
3. **Given** the Excel file is generated, **When** the operation finishes, **Then** the system file share sheet opens allowing the user to share via messaging apps, email, cloud drives, or save to device storage.

---

### User Story 3 - Export Financial Report to PDF (Priority: P3)

As a user who wants a clean, printable financial statement, I want to export a visually formatted PDF report for a selected month or period, so that I can print, share, or review my income, expense distribution, and net savings at a glance.

**Why this priority**: PDF reports provide immediate visual presentation with professional styling that is ready for printing, archiving, or sharing without requiring spreadsheet applications.

**Independent Test**: Can be fully tested by selecting a month, tapping "Xuất báo cáo PDF", and verifying the generated PDF contains an official header, summary stat boxes (Thu nhập, Chi tiêu, Số dư, Tích lũy), category breakdown distribution, and a clean transaction list.

**Acceptance Scenarios**:

1. **Given** financial records for a given month/year, **When** the user selects "Xuất báo cáo PDF", **Then** a multi-page/single-page styled PDF document is generated containing an executive summary header, income vs expense comparison, category spending table, and transaction logs.
2. **Given** the PDF is generated, **When** the generation completes, **Then** the user can preview the PDF and share/print it using the system share menu.

---

### User Story 4 - Export Transactions to CSV (Priority: P4)

As a user who prefers lightweight, universal tabular data for custom scripts, third-party budgeting software, or database ingestion, I want to export my transactions to a standard CSV file with proper UTF-8 encoding.

**Why this priority**: CSV provides universal interoperability across any platform or data tool with zero overhead.

**Independent Test**: Can be fully tested by selecting "Xuất CSV (.csv)", generating the file, opening it in standard text/spreadsheet editors, and verifying that comma delimiters, Vietnamese diacritics (UTF-8 BOM), date formats, and numeric fields parse cleanly.

**Acceptance Scenarios**:

1. **Given** transactions with Vietnamese text and notes, **When** the user exports to CSV, **Then** a UTF-8 with BOM encoded `.csv` file is produced so Vietnamese characters display accurately without encoding artifacts in Microsoft Excel or text editors.

---

### Edge Cases

- **Empty Database**: When exporting with no transactions or records in the selected period, the system should generate an empty table with headers and a zero summary rather than crashing or creating a corrupt file.
- **Large Datasets**: When exporting thousands of transactions, file generation should run asynchronously in the background with a progress/loading indicator, preventing UI freeze.
- **Special Characters & Commas in Notes**: In CSV export, fields containing commas, double quotes, or newlines must be properly quoted and escaped.
- **JSON Import Schema Mismatch**: If an imported JSON file comes from an older or newer schema version, the system should gracefully migrate missing fields with safe default values or alert if incompatible.
- **Foreign Key Integrity during Import**: When restoring JSON, categories, loans, and recurring configs must be imported in topological dependency order before transactions referencing them.
- **Storage/Permission Denials**: If the user cancels the file picker or denies storage permissions, the app must handle cancellation smoothly without errors.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST provide a dedicated "Xuất & Sao lưu dữ liệu" (Export & Backup) interface accessible from the Settings screen.
- **FR-002**: System MUST support exporting data in 4 standard formats: Excel (`.xlsx`), CSV (`.csv`), PDF (`.pdf`), and JSON (`.json`).
- **FR-003**: System MUST allow filtering export scope by date range (Tháng hiện tại, Tháng trước, Năm nay, Tùy chọn khoảng ngày, hoặc Tất cả thời gian) for Excel, CSV, and PDF exports.
- **FR-004**: System MUST format Excel (`.xlsx`) files with styled header rows, auto-fitted column widths, proper currency/number format rules, and separate sheets for Transactions, Category Budgets, and Loans.
- **FR-005**: System MUST encode CSV (`.csv`) files in UTF-8 with BOM to ensure accurate display of Vietnamese accents across all spreadsheet tools.
- **FR-006**: System MUST format PDF (`.pdf`) reports with an executive summary (Total Income, Total Expense, Net Balance, Savings Rate), a category breakdown summary table, and a detailed transaction ledger.
- **FR-007**: System MUST produce a complete JSON (`.json`) backup snapshot containing metadata (version, export timestamp, app info) and all core database tables:
  - `categories`
  - `transactions`
  - `monthly_budgets`
  - `category_monthly_budgets`
  - `loan_contacts`
  - `loan_transactions`
  - `recurring_configs`
  - `settings`
- **FR-008**: System MUST support JSON backup file restoration with file validation, structural integrity checks, and a pre-import summary dialog displaying entity counts.
- **FR-009**: System MUST provide two import modes for JSON restoration:
  - **Ghi đè toàn bộ (Overwrite / Replace)**: Clears existing data and restores the exact backup snapshot.
  - **Gộp dữ liệu (Merge / Append)**: Inserts missing categories and transactions without deleting existing unconflicted records.
- **FR-010**: System MUST execute JSON database restore inside an atomic database transaction with automatic rollback if any validation or insertion error occurs.
- **FR-011**: System MUST refresh all in-memory Riverpod providers (`transactionProvider`, `categoryProvider`, `loanProvider`, `monthlyBudgetFamily`, `settingsProvider`) immediately upon successful restore.
- **FR-012**: System MUST invoke the native OS Share Sheet / File Saver so users can save or send the generated files to external apps, email, cloud drives, or local storage.

### Key Entities *(include if feature involves data)*

- **ExportPayload**: Data structure containing filtered transactions, categories, budgets, and loans prepared for serialization into Excel, CSV, PDF, or JSON.
- **BackupSnapshot**: Structured JSON container with schema versioning (`version: 1`), export metadata (`exportedAt`, `platform`, `appVersion`), and complete database tables lists (`categories`, `transactions`, `monthly_budgets`, `category_monthly_budgets`, `loan_contacts`, `loan_transactions`, `recurring_configs`, `settings`).
- **ImportSummary**: Summary object calculated during backup file inspection showing total number of transactions, categories, budgets, and loans to be restored.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Users can export full transactions to Excel, CSV, PDF, or JSON in under 3 seconds for datasets with up to 2,000 transactions.
- **SC-002**: 100% of exported JSON backups can be imported back into a clean app instance with zero data loss or relation breakage.
- **SC-003**: 100% of Vietnamese characters and special currency symbols in CSV and Excel files display without garbled characters (mojibake).
- **SC-004**: Users can complete the full backup-and-share process in 3 taps from the Settings screen.
- **SC-005**: In case of a corrupted JSON file, 100% of abort scenarios rollback cleanly with zero unintended database mutations.

## Assumptions

- **Local Storage / Native Sharing**: File sharing and saving relies on standard cross-platform file saving / share dialogs (`share_plus` or `file_picker` / `path_provider`).
- **Offline First**: All export and backup generation happens 100% offline on the device without requiring an internet connection or external server.
- **Data Compatibility**: Recurring transactions and multi-month budget tables already existing in SQLite schema v12 are fully included in the backup structure.
- **Languages**: Export UI and generated document headers support both Vietnamese (`vi`) and English (`en`) according to user's selected language setting.
