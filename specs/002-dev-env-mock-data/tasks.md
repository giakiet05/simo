# Tasks: Isolate Dev Environment and Rich Mock Data Generator

**Feature**: [Isolate Dev Environment and Rich Mock Data Generator](spec.md)
**Plan**: [Implementation Plan](plan.md)
**Status**: Completed

---

## Phase 1: Setup

**Purpose**: Verify Android build script structure and prerequisites

- [X] T001 Verify Android build configuration in android/app/build.gradle.kts and android/app/src/main/AndroidManifest.xml

---

## Phase 2: Foundational

**Purpose**: Core prerequisites and localization strings for UI interactions

- [X] T002 [P] Add localization keys and getters for mock data actions in lib/utils/localization.dart

---

## Phase 3: User Story 1 - Coexistence of Dev and Production Apps (Priority: P1) 🎯 MVP

**Goal**: Isolate the development build (`debug`) from the production build (`release`) with separate Application IDs (`com.simolab.simo.dev` vs `com.simolab.simo`) and distinct app names (`Simo Dev` vs `Simo`).

**Independent Test**: Build the debug app and verify the app installs as `Simo Dev` with package `com.simolab.simo.dev` without deleting or overwriting the release app.

- [X] T003 [US1] Configure debug and release buildTypes with applicationIdSuffix and manifestPlaceholders in android/app/build.gradle.kts
- [X] T004 [US1] Update android:label to ${appName} in android/app/src/main/AndroidManifest.xml
- [X] T005 [US1] Verify Gradle build configuration for debug build in android/

---

## Phase 4: User Story 2 - Generate Comprehensive & Realistic Mock Data (Priority: P1)

**Goal**: Create a rich, diverse dataset containing exactly 5 income and 5 expense categories, 100+ transactions spanning March 2026 to August 2026, loan records, and varied timestamps.

**Independent Test**: Tap "Tạo dữ liệu mẫu" in Settings, confirm, and verify Dashboard, Transactions, and Statistics tabs are populated with 100+ records across 6 months.

- [X] T006 [US2] Update MockDataGenerator._createCategories to create exactly 5 Income categories and 5 Expense categories in lib/utils/mock_data_generator.dart
- [X] T007 [US2] Update MockDataGenerator._createTransactions to generate 100+ transactions across March to August 2026 with correct type, transaction_date, and diverse timestamps in lib/utils/mock_data_generator.dart
- [X] T008 [US2] Add mock loan contacts and loan transactions generator in lib/utils/mock_data_generator.dart
- [X] T009 [US2] Add "Tạo dữ liệu mẫu" button with confirmation dialog and provider refresh in lib/screens/settings_screen.dart

---

## Phase 5: User Story 3 - Reset / Clear Database for Fresh Testing (Priority: P2)

**Goal**: Provide a safe "Xóa toàn bộ dữ liệu" option that clears all tables and refreshes providers without requiring app restart.

**Independent Test**: Tap "Xóa toàn bộ dữ liệu" in Settings, confirm, and verify all transactions and custom categories are cleared while the UI refreshes to the empty state immediately.

- [X] T010 [US3] Update reset data handler in lib/screens/settings_screen.dart to clear all tables and refresh Riverpod providers

---

## Phase 6: Polish & Verification

**Purpose**: Validation, unit testing, and code quality

- [X] T011 [P] Create unit test for mock data generation count (>= 100 transactions, 5/5 categories) in test/unit/mock_data_generator_test.dart
- [X] T012 Run flutter analyze lib/ to ensure 0 lint errors
- [X] T013 Run quickstart verification scenarios in specs/002-dev-env-mock-data/quickstart.md

---

## Dependencies & Execution Order

### Phase Dependencies
- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Can run immediately
- **User Story 1 (Phase 3)**: MVP - Android build isolation
- **User Story 2 (Phase 4)**: Mock data generator service and Settings trigger
- **User Story 3 (Phase 5)**: Data reset and state refresh
- **Polish (Phase 6)**: Tests & verification

---

## Implementation Strategy

### MVP First (User Story 1)
1. Complete T001 → T005
2. Validate debug build installs as `com.simolab.simo.dev` (`Simo Dev`) without touching production app

### Incremental Delivery (User Story 2 & 3)
1. Implement 5/5 categories + 100+ transactions in `MockDataGenerator` (T006-T008)
2. Integrate interactive triggers in `SettingsScreen` (T009-T010)
3. Run tests and quickstart validation (T011-T013)
