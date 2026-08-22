# Research: Data Export & Backup (Excel, CSV, PDF, JSON Import/Export)

## Technical Decisions & Rationale

### 1. Excel Generation (.xlsx)
- **Decision**: Use `excel: ^4.0.6` (Pure Dart package).
- **Rationale**: 
  - Pure Dart implementation with zero native C/C++ or platform-specific dependencies.
  - Full support for multiple sheets (`Giao dịch`, `Ngân sách danh mục`, `Sổ nợ`, `Giao dịch định kỳ`).
  - Allows cell styling, custom header colors, column widths, and cell data types (Text, Numeric, Date).
- **Alternatives Considered**:
  - `syncfusion_flutter_xlsio`: Feature-rich but requires commercial license key for commercial apps.
  - Manual XML/zip creation: High maintenance overhead and error-prone.

---

### 2. CSV Generation (.csv) & Vietnamese Character Encoding
- **Decision**: Use `csv: ^6.0.0` with explicit UTF-8 BOM (`\uFEFF`) prefix.
- **Rationale**:
  - Standard RFC 4180 CSV generation handling escaping of commas, quotes, and newlines in transaction notes.
  - Prepending `\uFEFF` (Byte Order Mark) ensures Microsoft Excel on Windows/macOS automatically opens the file with UTF-8 encoding, displaying Vietnamese diacritics perfectly without mojibake.
- **Alternatives Considered**:
  - Raw string splitting with `.join(',')`: Vulnerable to broken formatting when notes contain commas or quotes.

---

### 3. PDF Generation (.pdf) & Vietnamese Font Rendering
- **Decision**: Use `pdf: ^3.11.1` and `printing: ^5.13.2` with `PdfGoogleFonts.robotoRegular()` / `robotoBold()`.
- **Rationale**:
  - Standard Flutter PDF generation engine with declarative widget structure (`pdf/widgets.dart`).
  - Google Fonts Roboto handles complete Vietnamese Unicode character ranges without missing glyphs.
  - `printing` package provides easy document sharing, printing, and file preview capabilities across iOS, Android, and Desktop.
- **Alternatives Considered**:
  - HTML to PDF WebView rendering: Heavyweight, inconsistent rendering across platforms, and requires active headless webview.

---

### 4. Full Backup Snapshot & Restore Architecture (.json)
- **Decision**: Single-file JSON snapshot with schema versioning (`version: 1`), metadata, and table arrays.
- **Rationale**:
  - JSON is human-readable, universal, and easily inspectable.
  - Contains complete snapshot: `categories`, `transactions`, `monthly_budgets`, `category_monthly_budgets`, `loan_contacts`, `loan_transactions`, `recurring_configs`, and `settings`.
  - Import process executes inside an atomic SQLite `db.transaction()`:
    - Step 1: Parse and validate JSON schema.
    - Step 2: Extract and display counts in pre-import confirmation modal.
    - Step 3: Insert entities in dependency order (`categories` -> `recurring_configs` -> `transactions`, `loan_contacts` -> `loan_transactions`, `monthly_budgets` -> `category_monthly_budgets`).
    - Step 4: If any step fails, transaction automatically rolls back with zero database corruption.
    - Step 5: Trigger Riverpod state invalidation/reloading across all providers.
- **Modes Supported**:
  - `overwrite`: Truncates existing tables and inserts all backup records.
  - `merge`: Skips duplicate IDs or matches categories by name, preserves existing distinct entries.

---

### 5. File Picker & Native Sharing
- **Decision**: Use `share_plus: ^10.1.4` for exporting and `file_picker: ^8.1.7` for backup file importing.
- **Rationale**:
  - `share_plus` is the official Flutter community standard for triggering the native iOS/Android share sheet (Share to Zalo, Telegram, Google Drive, Email, or Save to Files).
  - `file_picker` allows selecting `.json` files seamlessly across mobile and desktop.
