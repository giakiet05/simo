# Research & Technical Decisions: Dev Environment Isolation & Rich Mock Data

## Overview
This document outlines technical decisions for configuring distinct Application IDs for development vs production Android builds and upgrading the mock data generator with a rich 6-month timeline and developer settings UI.

---

### Decision 1: Android Build Type & Application ID Suffix
- **Decision**: In `android/app/build.gradle.kts`, configure `buildTypes`:
  - `debug`: Add `applicationIdSuffix = ".dev"` and `manifestPlaceholders["appName"] = "Simo Dev"`.
  - `release`: Retain base `applicationId = "com.simolab.simo"` and `manifestPlaceholders["appName"] = "Simo"`.
  - In `AndroidManifest.xml`, bind `android:label="${appName}"`.
- **Rationale**: Android OS identifies apps exclusively by their Application ID (`package`). Appending `.dev` creates a completely separate app sandbox on the physical device with its own SQLite storage (`/data/data/com.simolab.simo.dev/databases/simo.db`), making it impossible for `flutter run` to uninstall or touch `com.simolab.simo`.
- **Alternatives Considered**:
  - *Product Flavors (`flavorDimensions`)*: Adds unnecessary complexity to build commands (`flutter run --flavor dev`). Using `buildTypes.debug` works out-of-the-box with simple `flutter run`.

---

### Decision 2: Rich Mock Data Structure & Distribution
- **Decision**: Upgrade `MockDataGenerator` to generate:
  - Default realistic Categories: 4 Income categories (Lương, Thưởng, Đầu tư, Thu nhập phụ) and 7 Expense categories (Ăn uống, Đi lại, Mua sắm, Hóa đơn & Tiện ích, Giải trí, Sức khỏe, Giáo dục).
  - Loan Contacts & Transactions: 2-3 contacts with loan/borrow records and partial repayments.
  - Transactions Timeline: From March 2026 to August 2026 (current month).
  - Varied Timestamps: Some transactions created on time, some backdated (`transactionDate` < `createdAt`), and some edited (`updatedAt` > `createdAt`).
- **Rationale**: Directly addresses developer testing needs for monthly budget charts, category breakdowns, sorting behavior, and loan tracking.

---

### Decision 3: Developer Settings UI & State Invalidation
- **Decision**: Add a "Dữ liệu & Thử nghiệm" (Data & Testing) section in `SettingsScreen` with:
  - "Tạo dữ liệu mẫu" (Generate Mock Data) with confirmation dialog and progress indicator.
  - Refresh `transactionProvider`, `categoryProvider`, `loanProvider` immediately so UI reflects data without needing app restart.
- **Rationale**: Eliminates the need to restart the app or run custom test scripts to reset or generate data.
