# Implementation Plan: Saving Goals (Mục tiêu tiết kiệm / Hũ tích lũy)

**Branch**: `005-saving-goals` | **Spec**: [specs/005-saving-goals/spec.md](spec.md)

## Summary

This plan outlines the architecture, database migrations, state management, and user interfaces for **Saving Goals (Mục tiêu tiết kiệm / Hũ tích lũy)** in Simo. Users will be able to set milestone goals with deadlines, deposit/withdraw funds with transparent audit logs, track percentage progress and monthly pacing recommendations, and backup their goals seamlessly.

## Technical Context

- **Platform**: Flutter / Dart (Cross-platform Android / iOS / Desktop)
- **State Management**: Riverpod (`flutter_riverpod: ^2.6.1`)
- **Database**: SQLite (`sqflite: ^2.4.1`)
- **Localization**: English, Vietnamese, Chinese (`lib/utils/localization.dart`)
- **Backup & Export**: JSON Backup (`BackupService`) & Excel (`ExportService`)

## Architecture & Project Structure

```
lib/
├── models/
│   ├── saving_goal.dart               # SavingGoal entity model
│   └── saving_goal_log.dart           # SavingGoalLog entity model
├── repositories/
│   ├── database_helper.dart           # Schema v7 migration (saving_goals, saving_goal_logs)
│   └── saving_goal_repository.dart    # SQLite repository implementation
├── providers/
│   └── saving_goal_provider.dart      # Riverpod state notifier
├── screens/
│   ├── saving_goals_screen.dart       # Main saving goals list & overview
│   └── saving_goal_detail_screen.dart # Goal detail & transaction history timeline
├── widgets/
│   ├── saving_goal_card.dart          # Goal progress card widget
│   ├── saving_goal_form_modal.dart    # Create / edit goal bottom sheet
│   └── saving_goal_log_modal.dart     # Deposit / withdraw bottom sheet
```

## Phased Execution Strategy

- **Phase 1 (Database & Models)**:
  - SQLite schema upgrade in `DatabaseHelper` (create `saving_goals` and `saving_goal_logs`).
  - Create `SavingGoal` and `SavingGoalLog` models.
  - Create `SavingGoalRepository` with CRUD and atomic deposit/withdraw methods.
  - Write repository unit tests.
- **Phase 2 (State Management & Logic)**:
  - Implement `SavingGoalNotifier` and `savingGoalProvider`.
  - Add smart pacing calculation logic.
- **Phase 3 (User Interface)**:
  - Build `SavingGoalsScreen` with overview card and list view.
  - Build `SavingGoalFormModal` (create/edit with icon & color selection).
  - Build `SavingGoalDetailScreen` with timeline and deposit/withdraw modal.
  - Add navigation entry point from Dashboard Quick Access Hub and Drawer.
- **Phase 4 (Backup & Export Integration)**:
  - Update `BackupSnapshot` and `BackupService` to backup/restore `saving_goals` and `saving_goal_logs`.
  - Update `ExportService.exportToExcel` to include Saving Goals sheet.
- **Phase 5 (Verification & Tests)**:
  - Unit tests for repository, models, and backup integration.
  - End-to-end validation with `quickstart.md`.
