# Tasks: Data Export & Backup (Excel, CSV, PDF, JSON Import/Export)

**Branch**: `004-export-and-backup` | **Spec**: [specs/004-export-and-backup/spec.md](spec.md) | **Plan**: [specs/004-export-and-backup/plan.md](plan.md)

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and dependency setup

- [x] T001 Add export & backup dependencies (`excel: ^4.0.6`, `csv: ^6.0.0`, `pdf: ^3.11.1`, `printing: ^5.13.2`, `share_plus: ^10.1.4`, `file_picker: ^8.1.7`) in `pubspec.yaml`
- [x] T002 [P] Add localization strings for Export & Backup (Vietnamese & English) in `lib/l10n/app_localizations.dart`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core data models and file utility helpers required by all export and backup services

- [x] T003 [P] Create `ExportFilterParams` model in `lib/models/export_filter_params.dart`
- [x] T004 [P] Create `BackupSnapshot` and `ImportInspection` models in `lib/models/backup_snapshot.dart` and `lib/models/import_inspection.dart`
- [x] T005 [P] Create file path and UTF-8 BOM helper utilities in `lib/services/file_helper.dart`
- [x] T006 [P] Add unit tests for export filter parameters and snapshot serialization in `test/unit/export_backup_models_test.dart`

**Checkpoint**: Core models and file helpers ready - User story implementation can begin

---

## Phase 3: User Story 1 - Full Data Backup & Restore via JSON (Priority: P1) 🎯 MVP

**Goal**: Complete snapshot of all SQLite database tables into `.json` file and safe restoration (Overwrite vs Merge) with transaction safety.

**Independent Test**: Export database to JSON, modify or reset data in app, restore from the JSON file, and verify all records across all tables are restored with 100% accuracy.

### Tests for User Story 1
- [x] T007 [P] [US1] Unit test for JSON backup snapshot serializer and deserializer in `test/unit/backup_service_test.dart`

### Implementation for User Story 1
- [x] T008 [US1] Implement `BackupService.createBackupFile()` to serialize all SQLite tables in `lib/services/backup_service.dart`
- [x] T009 [US1] Implement `BackupService.inspectBackupFile()` for pre-import validation and count extraction in `lib/services/backup_service.dart`
- [x] T010 [US1] Implement `BackupService.restoreFromBackup()` with Overwrite and Merge modes inside atomic SQLite transaction in `lib/services/backup_service.dart`
- [x] T011 [US1] Create `BackupNotifier` and `backupProvider` in `lib/providers/export_backup_provider.dart` to manage state and invalidate existing Riverpod providers
- [x] T012 [US1] Build "Sao lưu & Khôi phục" UI tab with backup generator, file picker, and pre-restore inspection modal in `lib/screens/export_backup_screen.dart`

**Checkpoint**: At this point, User Story 1 (Full JSON Backup & Restore) is fully functional and testable independently

---

## Phase 4: User Story 2 - Export Transactions to Excel (.xlsx) (Priority: P2)

**Goal**: Export transactions and financial summaries to a formatted multi-sheet Excel (.xlsx) workbook and share via native OS share sheet.

**Independent Test**: Filter date range, tap Export to Excel, open generated file in spreadsheet app, and verify formatted sheets (`Giao dịch`, `Ngân sách danh mục`, `Sổ nợ`, `Giao dịch định kỳ`) and totals.

### Tests for User Story 2
- [x] T013 [P] [US2] Unit test for Excel workbook builder in `test/unit/excel_export_test.dart`

### Implementation for User Story 2
- [x] T014 [US2] Implement `ExportService.exportToExcel()` with multi-sheet generation, styling, and number formatting in `lib/services/export_service.dart`
- [x] T015 [US2] Implement `ExportService.shareFile()` to invoke native OS Share Sheet via `share_plus` in `lib/services/export_service.dart`
- [x] T016 [US2] Add Excel Export card & date range filter selector to "Xuất báo cáo" tab in `lib/screens/export_backup_screen.dart`

**Checkpoint**: User Stories 1 AND 2 work independently

---

## Phase 5: User Story 3 - Export Financial Report to PDF (Priority: P3)

**Goal**: Generate styled A4 printable PDF financial statements with Roboto Vietnamese fonts and trigger native share/print.

**Independent Test**: Export PDF for a selected month, open/print document, and verify executive header, summary cards, category table, and transaction logs.

### Tests for User Story 3
- [x] T017 [P] [US3] Unit test for PDF financial statement builder in `test/unit/pdf_export_test.dart`

### Implementation for User Story 3
- [x] T018 [US3] Implement `ExportService.exportToPdf()` with Roboto font loading, summary header, category breakdown table, and transaction ledger in `lib/services/export_service.dart`
- [x] T019 [US3] Add PDF Export card & preview trigger to "Xuất báo cáo" tab in `lib/screens/export_backup_screen.dart`

**Checkpoint**: User Stories 1, 2, and 3 work independently

---

## Phase 6: User Story 4 - Export Transactions to CSV (Priority: P4)

**Goal**: Export transactions to universal CSV with UTF-8 BOM encoding for seamless display in Microsoft Excel and text editors without mojibake.

**Independent Test**: Export CSV, open in text editor and Microsoft Excel, and verify Vietnamese text, quotes/commas escaping, and headers.

### Tests for User Story 4
- [x] T020 [P] [US4] Unit test for CSV export with UTF-8 BOM and RFC 4180 escaping in `test/unit/csv_export_test.dart`

### Implementation for User Story 4
- [x] T021 [US4] Implement `ExportService.exportToCsv()` with UTF-8 BOM prefix and column mapping in `lib/services/export_service.dart`
- [x] T022 [US4] Add CSV Export card to "Xuất báo cáo" tab in `lib/screens/export_backup_screen.dart`

**Checkpoint**: All 4 user stories are fully functional

---

## Phase 7: Polish & Cross-Cutting Concerns

**Purpose**: Integration into Settings, UI polish, and end-to-end verification

- [x] T023 Add "Xuất & Sao lưu dữ liệu" list tile entry point in `lib/screens/settings_screen.dart`
- [x] T024 [P] Add Banner ad and layout responsiveness to `lib/screens/export_backup_screen.dart`
- [x] T025 Run all unit tests with `flutter test --concurrency=1 test/unit/` and check `flutter analyze`
- [x] T026 Execute end-to-end validation scenarios in `specs/004-export-and-backup/quickstart.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup (T001, T002) - BLOCKS all user stories
- **User Stories (Phase 3 - Phase 6)**: All depend on Foundational completion (T003 - T006)
  - US1 (P1 - Backup & Restore) 🎯 MVP
  - US2 (P2 - Excel Export)
  - US3 (P3 - PDF Report)
  - US4 (P4 - CSV Export)
- **Polish (Phase 7)**: Depends on US1-US4 completion

### Parallel Opportunities

- T002 (Localization) can run in parallel with T001 (Pubspec)
- T003, T004, T005, T006 can run in parallel during Foundational phase
- Unit tests T007, T013, T017, T020 can run in parallel for their respective stories
- T024 (Ad widget & UI polish) can run in parallel with T023 (Settings integration)

---

## Implementation Strategy

### MVP First (User Story 1 Only)
1. Complete Phase 1: Setup (Dependencies & L10n)
2. Complete Phase 2: Foundational (Models & Helpers)
3. Complete Phase 3: User Story 1 (JSON Backup & Restore)
4. **VALIDATE**: Test full backup & restore on clean database

### Incremental Delivery
1. Add User Story 2 (Excel Export) → Test Excel file & multi-sheet structure
2. Add User Story 3 (PDF Export) → Test PDF report & font rendering
3. Add User Story 4 (CSV Export) → Test CSV UTF-8 BOM encoding
4. Complete Phase 7 (Settings entry point & full verification)
