# Implementation Plan: Features Hub Screen on Bottom Navigation Bar (Màn hình Chức năng)

**Branch**: `013-features-hub-tab` | **Date**: 2026-09-03 | **Spec**: [specs/013-features-hub-tab/spec.md](spec.md)

**Input**: Feature specification from `/specs/013-features-hub-tab/spec.md`

## Summary

Replace the standalone "Sổ nợ" tab on the bottom navigation bar with a dedicated "Chức năng" (Features Hub) screen that provides a unified, structured workspace for all SIMO financial utilities with live preview summaries and one-tap quick actions.

## Technical Context

**Language/Version**: Dart 3.x / Flutter 3.x
**Primary Dependencies**: `flutter_riverpod`, `intl`
**Target Platform**: Android & iOS
**Testing**: Unit and widget tests via `flutter test --concurrency=1 test/unit/`
**Scale/Scope**: 3 files (`features_screen.dart`, `home_screen.dart`, `localization.dart`)

## Constitution Check

- **Design System Alignment**: Follows SIMO 16dp rounded card radius, subtle outlines with `.withValues(alpha: 0.12)`, zero elevation, clean typography. **PASS**
- **Localization Consistency**: Extends `AppLocalizations` with bilingual strings for sections and labels. **PASS**
- **Clean Architecture**: Decoupled presentation with existing Riverpod providers. **PASS**

## Project Structure

### Documentation (this feature)

```text
specs/013-features-hub-tab/
├── plan.md              # This file
├── research.md          # Architectural decisions
├── data-model.md        # UI models
├── quickstart.md        # Validation scenarios
├── contracts/
│   └── features-hub-contract.md # Screen and navigation contracts
└── tasks.md             # Tasks file (via /speckit-tasks)
```

### Source Code Files Affected

```text
lib/
├── screens/
│   ├── features_screen.dart   # New screen: Features Hub with live preview cards
│   └── home_screen.dart       # Replace tab 3 with FeaturesScreen and new tab icon/label
└── utils/
    └── localization.dart      # Localization keys for Features Hub
```
