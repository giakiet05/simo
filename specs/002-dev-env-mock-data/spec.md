# Feature Specification: Isolate Dev Environment and Rich Mock Data Generator

**Feature Branch**: `002-dev-env-mock-data`

**Created**: 2026-08-20

**Status**: Draft

**Input**: User description: "trước mắt làm 2 việc: tách app dev và app thật để tránh bị mất data và tạo lại bộ dữ liệu mẫu đa dạng"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Coexistence of Dev and Production Apps (Priority: P1) 🎯 MVP

As a developer using the Simo app daily for personal bookkeeping, I want the development build (`debug`) and production build (`release`) to install as separate apps on my phone with independent Application IDs (`com.simolab.simo.dev` vs `com.simolab.simo`) and distinct app names (`Simo Dev` vs `Simo`), so that running `flutter run` or testing new features will NEVER overwrite, uninstall, or wipe my real production financial records.

**Why this priority**: Prevents critical data loss. Ensures the user can safely develop and test without risking their real transaction database.

**Independent Test**: Install the release build on device, then run the debug build via `flutter run`. Verify that two separate icons (`Simo` and `Simo Dev`) exist on the device launcher and data created in one app does not affect the other.

**Acceptance Scenarios**:

1. **Given** the production app `Simo` is installed with real transactions, **When** the developer launches the debug build via `flutter run`, **Then** the debug app installs as `Simo Dev` without prompting to uninstall or deleting data from `Simo`.
2. **Given** both apps installed, **When** inspecting the application package IDs, **Then** the debug app uses `com.simolab.simo.dev` and the release app uses `com.simolab.simo`.
3. **Given** changes or resets made inside `Simo Dev`, **When** opening `Simo`, **Then** the production data remains intact and isolated.

---

### User Story 2 - Generate Comprehensive & Realistic Mock Data (Priority: P1)

As a user/developer testing the app, I want to trigger a rich mock data generation action from Settings that creates a realistic financial history spanning from March 2026 to August 2026 (including multiple categories, income, expense, loans, and varying timestamps), so that I can immediately test and visualize all charts, filters, and transaction features.

**Why this priority**: Rapidly restores test data and allows comprehensive verification of sorting, monthly summaries, loan management, and timestamp features.

**Independent Test**: Go to Settings -> Tap "Tạo dữ liệu mẫu (Mock Data)" -> Verify that Dashboard, Transactions, and Statistics tabs are populated with 50+ diverse records spanning March to August 2026 with correct calculations.

**Acceptance Scenarios**:

1. **Given** an empty or existing app database, **When** the user taps "Tạo dữ liệu mẫu" in Settings and confirms, **Then** the system generates transactions across months 3, 4, 5, 6, 7, 8 of 2026 with realistic categories (Ăn uống, Đi lại, Mua sắm, Lương, Thưởng, Vay nợ, etc.).
2. **Given** generated mock data, **When** viewing transaction details, **Then** transactions have distinct `transactionDate`, `createdAt`, and `updatedAt` timestamps illustrating various creation and update dates.
3. **Given** generated mock data, **When** navigating to Dashboard and Statistics, **Then** all charts (monthly spending trend, category distribution, loan balance) reflect the newly generated data instantly.

---

### User Story 3 - Reset / Clear Database for Fresh Testing (Priority: P2)

As a developer, I want a safe "Xóa toàn bộ dữ liệu (Clear All Data)" option in Developer / Settings options with a confirmation prompt, so that I can quickly reset the database to a clean state whenever needed without having to uninstall the app.

**Why this priority**: Improves developer convenience and provides a clean test baseline.

**Independent Test**: Tap "Xóa toàn bộ dữ liệu", confirm the prompt, and verify all transactions and custom categories are cleared while default system loan categories remain intact.

**Acceptance Scenarios**:

1. **Given** existing transactions in the app, **When** user selects "Xóa toàn bộ dữ liệu" and confirms, **Then** all transactions, custom categories, and configs are deleted and the UI refreshes to the empty state.
2. **Given** the confirmation dialog, **When** user taps Cancel, **Then** no data is modified or deleted.

---

### Edge Cases

- **Generating mock data multiple times**: System appends new mock records or offers a clean overwrite to avoid duplicate primary key collisions.
- **Offline operation**: Mock data generator runs entirely locally within SQLite without network dependency.
- **Timezone & Month boundaries**: Mock transactions generated across leap months or 30/31-day months must have valid calendar dates.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: System MUST configure Android build types/flavors such that Debug builds have `applicationIdSuffix = ".dev"` (or `com.simolab.simo.dev`) and app title `Simo Dev`, while Release builds retain `com.simolab.simo` and app title `Simo`.
- **FR-002**: Operating system sandbox MUST guarantee 100% data isolation (SQLite database and SharedPreferences) between `com.simolab.simo.dev` and `com.simolab.simo`.
- **FR-003**: System MUST provide a mock data generator service capable of creating:
  - Exactly 5 Income categories (`Lương`, `Thưởng`, `Đầu tư`, `Kinh doanh`, `Thu nhập khác`) and 5 Expense categories (`Ăn uống`, `Đi lại`, `Mua sắm`, `Hóa đơn & Tiện ích`, `Giải trí & Du lịch`).
  - At least 100+ transactions distributed across March 2026 to August 2026 (approximately 18-25 transactions per month).
  - Loan and debt records (borrowing, lending, repaying, collecting) with contact names.
  - Realistic monetary amounts (e.g. 20,000 VND to 25,000,000 VND).
- **FR-004**: Generated mock transactions MUST include distinct timestamp combinations:
  - Backdated transactions where `transactionDate` is earlier than `createdAt`.
  - Updated transactions where `updatedAt` is later than `createdAt`.
- **FR-005**: System MUST provide interactive buttons in the Settings screen (under a Developer Tools / Quản lý dữ liệu section):
  - "Tạo dữ liệu mẫu (Mock Data)"
  - "Xóa toàn bộ dữ liệu (Clear All Data)"
- **FR-006**: System MUST show a confirmation dialog before executing mock data generation or database clearing.
- **FR-007**: System MUST automatically notify and refresh Riverpod providers (`transactionProvider`, `categoryProvider`, `loanProvider`) upon mock data generation or deletion.

### Key Entities *(include if feature involves data)*

- **Build Configuration**:
  - `applicationId`: `com.simolab.simo` (Release) / `com.simolab.simo.dev` (Debug)
  - `appName`: `Simo` (Release) / `Simo Dev` (Debug)
- **Mock Dataset**:
  - Categories: Food, Transport, Shopping, Bills, Entertainment, Health, Salary, Bonus, Investment.
  - Transactions: Realistic monthly transactions covering 6 months (March - August 2026).
  - Loan Contacts & Transactions: Active loans and partial repayments.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 0% chance of `flutter run` debug sessions uninstalling or corrupting the production app `com.simolab.simo`.
- **SC-002**: Generating mock data takes less than 2 seconds for 100+ records and updates all screens without app restart.
- **SC-003**: 100% of charts in Dashboard and Statistics render rich data across the 6-month timeline (March - August 2026).
- **SC-004**: Users can clearly differentiate the dev app from the production app on the phone home screen by app title (`Simo Dev`).

## Assumptions

- Debug builds will be used for daily development and testing (`flutter run`).
- Personal daily bookkeeping will use the release build (`flutter run --release` or installed release APK).
- Android OS natively isolates data by `applicationId`.

