# Implementation Plan: Align App-wide UI to SIMO Design System

**Branch**: `007-align-app-design-system` | **Spec**: [specs/007-align-app-design-system/spec.md](spec.md)

## Summary

Systematically refactor all screens, widgets, and dialogs across the SIMO codebase to achieve 100% adherence to the SIMO Design System (`docs/design_system/`). This includes standardizing AppBars, making all filter chip rows overflow-proof, enforcing 20dp modal top radii, and migrating all deprecated `.withOpacity(...)` calls to `.withValues(alpha: ...)`.

## Phased Execution Strategy

- **Phase 1 (AppBars & Action Buttons)**: Refactor AppBars in `RecurringScreen`, `LoanScreen`, and `CategoryScreen`.
- **Phase 2 (Filter Chips Overflow Prevention)**: Wrap filter chips in `SingleChildScrollView` in `LoanScreen`, `RecurringScreen`, and `StatisticsScreen`.
- **Phase 3 (Modals & Cards)**: Standardize bottom sheets and card borders across all screens.
- **Phase 4 (API Deprecation Migration)**: Migrate all `.withOpacity` calls to `.withValues(alpha: ...)`.
- **Phase 5 (Verification & Polish)**: Run `flutter analyze lib/` and `flutter test`.
