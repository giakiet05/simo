# Implementation Plan: Data Export & Backup (Excel, CSV, PDF, JSON Import/Export)

**Branch**: `004-export-and-backup` | **Date**: 2026-08-22 | **Spec**: [specs/004-export-and-backup/spec.md](spec.md)

**Input**: Feature specification from `specs/004-export-and-backup/spec.md`

## Summary

Implement comprehensive data export and backup capabilities for the Simo app:
1. **Full Database Backup & Restore (JSON)**: Complete schema snapshot covering all tables (`categories`, `transactions`, `monthly_budgets`, `category_monthly_budgets`, `loan_contacts`, `loan_transactions`, `recurring_configs`, `settings`) with pre-import inspection, conflict resolution (Overwrite vs Merge), and atomic SQLite transaction safety.
2. **Multi-sheet Excel (.xlsx) Export**: Formatted workbooks with customizable time filters and dedicated sheets for Transactions, Category Budgets, and Loans using the pure Dart `excel` package.
3. **Printable PDF (.pdf) Reports**: Visual financial statements with executive summaries, category charts/tables, and logs using `pdf` & `printing` with Roboto Vietnamese fonts.
4. **Universal CSV (.csv) Export**: UTF-8 with BOM encoded tabular export for universal spreadsheet compatibility.
5. **Cross-platform Native Sharing**: System share sheet via `share_plus` and file picking via `file_picker`.

## Technical Context

**Language/Version**: Dart 3.10+, Flutter 3.24+

**Primary Dependencies**:
- `excel: ^4.0.6` (Pure Dart Excel generation)
- `csv: ^6.0.0` (RFC 4180 CSV serializer)
- `pdf: ^3.11.1` & `printing: ^5.13.2` (PDF document generator & print/preview)
- `share_plus: ^10.1.4` (Native OS Share Sheet)
- `file_picker: ^8.1.7` (File selector for JSON backup files)
- `path_provider: ^2.1.5` (Temporary file storage before sharing)
- `sqflite: ^2.4.1` (Atomic database transactions)
- `flutter_riverpod: ^2.6.1` (State management and provider invalidation)

**Storage**: SQLite database (`simo.db`) + Local filesystem temporary cache.

**Testing**: Flutter test (`flutter test test/unit/`) with dedicated unit tests for Excel, CSV, PDF, and JSON backup/restore serialization.

**Target Platform**: Android, iOS, macOS, Windows, Linux.

**Project Type**: Mobile Application.

**Performance Goals**: Export up to 2,000 transactions and generate full multi-sheet Excel / PDF / JSON in under 3 seconds with background execution.

**Constraints**: 100% offline-capable, zero data loss, safe database rollbacks on import errors.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- **Simplicity & Modularity**: Export and Backup logic isolated in `ExportService` and `BackupService` under `lib/services/`.
- **Test-First**: Unit tests written for JSON schema serialization, backup validation, and database restore integrity.
- **Graceful Error Handling**: Corrupted or incompatible files aborted cleanly without mutating database state.

## Project Structure

### Documentation (this feature)

```text
specs/004-export-and-backup/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── export-backup-service-contract.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code Architecture

```text
lib/
├── models/
│   ├── export_filter_params.dart      # Export filter model (date range, type)
│   ├── backup_snapshot.dart           # JSON snapshot structure & serialization
│   └── import_inspection.dart         # Backup validation & entity count summary
├── services/
│   ├── export_service.dart            # Excel, CSV, PDF generator & share triggers
│   └── backup_service.dart            # JSON backup snapshot creator & DB restorer
├── providers/
│   └── export_backup_provider.dart    # Riverpod provider for export & backup states
├── screens/
│   ├── export_backup_screen.dart      # Export & Backup UI (2 tabs: Xuất báo cáo, Sao lưu)
│   └── settings_screen.dart           # Entry point linking to ExportBackupScreen
└── l10n/
    └── app_localizations.dart         # Vietnamese & English strings for export & backup
```
