# Implementation Plan: Isolate Dev Environment and Rich Mock Data Generator

**Branch**: `002-dev-env-mock-data` | **Date**: 2026-08-20 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `specs/002-dev-env-mock-data/spec.md`

## Summary

Isolate Android development build from production build using `applicationIdSuffix = ".dev"` and app label `Simo Dev` to prevent data loss or package collisions during development. Upgrade the mock data generator to create a rich dataset of 100+ transactions spanning March 2026 to August 2026 across exactly 5 expense and 5 income categories, loans, and diverse timestamps, and integrate interactive trigger controls into the Settings screen.

## Technical Context

**Language/Version**: Dart 3.10+ / Flutter 3.x

**Primary Dependencies**: `flutter_riverpod` (^2.6.1), `sqflite` (^2.4.1), `uuid` (^4.5.1)

**Storage**: SQLite (`simo.db`) isolated per Application ID sandbox (`com.simolab.simo.dev` vs `com.simolab.simo`)

**Testing**: `flutter_test` unit tests

**Target Platform**: Android & iOS mobile app

**Project Type**: Flutter Mobile Application

**Performance Goals**: Generate 50+ mock transactions in <2s; instant provider refresh

**Constraints**: Zero regression to production release build identifier `com.simolab.simo`

**Scale/Scope**: Affects `android/app/build.gradle.kts`, `AndroidManifest.xml`, `MockDataGenerator`, and `SettingsScreen`.

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- Principle I (Modularity): PASSED - Mock data generator encapsulated in utility service.
- Principle II (Data Safety & Isolation): PASSED - Operating system sandbox provides native separation.
- Principle III (Test-First): PASSED - Verification scenarios defined in quickstart.md.

## Project Structure

### Documentation (this feature)

```text
specs/002-dev-env-mock-data/
├── plan.md              # This file (/speckit-plan command output)
├── research.md          # Phase 0 output (/speckit-plan command)
├── data-model.md        # Phase 1 output (/speckit-plan command)
├── quickstart.md        # Phase 1 output (/speckit-plan command)
├── contracts/           # Phase 1 output (/speckit-plan command)
│   └── dev-env-contracts.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (repository root)

```text
android/app/
├── build.gradle.kts                   # Add debug applicationIdSuffix & manifestPlaceholders
└── src/main/AndroidManifest.xml       # Use android:label="${appName}"

lib/
├── utils/
│   └── mock_data_generator.dart       # Comprehensive 6-month mock data logic
├── screens/
│   └── settings_screen.dart           # UI buttons for mock data generation and reset
├── providers/
    ├── transaction_provider.dart      # Reload trigger
    └── category_provider.dart         # Reload trigger

test/
└── unit/
    └── mock_data_generator_test.dart  # Unit tests for mock data generation logic
```

**Structure Decision**: Android build configuration update combined with Flutter presentation/service enhancement.

## Complexity Tracking

| Violation | Why Needed | Simpler Alternative Rejected Because |
|---|---|---|
| None | N/A | N/A |
