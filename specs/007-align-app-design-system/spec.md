# Feature Specification: Align App-wide UI to SIMO Design System

**Feature Branch**: `007-align-app-design-system`

**Created**: 2026-08-22

**Status**: Draft

**Input**: User description: "giờ tao nghĩ là mình nên đi đồng bộ cái thiết kế cho toàn app. Mày review lại toàn bộ source code và phát hiện các điểm chưa đồng bộ cho tao, sau đó lên kế hoạch fix hết."

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Standardize AppBars & Primary Action Buttons (Priority: P1) 🎯 MVP

As a user navigating across different screens (Recurring, Loans, Categories, Savings, Settings), I want all AppBars to have a consistent flat aesthetic (`elevation: 0`) and standard top-right action buttons (`IconButton(icon: Icon(Icons.add))` with tooltips), so that screen headers feel unified and predictable.

**Why this priority**: Screen headers are the most prominent and frequently viewed element in the entire app.

**Independent Test**: Can be validated by opening `RecurringScreen`, `LoanScreen`, `CategoryScreen`, and `SavingGoalsScreen` and verifying that all AppBars have flat background styling (`elevation: 0`) and top-right `+` action buttons.

**Acceptance Scenarios**:

1. **Given** `RecurringScreen`, **When** viewed by the user, **Then** the AppBar has `elevation: 0`, standard theme color, and a clean `IconButton(icon: Icon(Icons.add))` action replacing the previous heavy button container.
2. **Given** `LoanScreen`, **When** viewed by the user, **Then** the AppBar uses standard flat styling without `inversePrimary` tint.
3. **Given** `CategoryScreen`, **When** viewed by the user, **Then** the top-right create action aligns with the standard `IconButton(icon: Icon(Icons.add))` pattern.

---

### User Story 2 - Overflow-Proof Horizontal Filter Chips (Priority: P1)

As a user on devices with narrow screens or using longer languages (e.g. Vietnamese/Chinese), I want all filter chip bars (Loans, Recurring, Statistics, Saving Goals) to scroll smoothly horizontally without overflowing or throwing `RenderFlex` layout exceptions.

**Why this priority**: Prevents critical UI rendering errors and ensures perfect responsiveness across all screen sizes and localizations.

**Independent Test**: Can be validated by switching language to Vietnamese, opening `LoanScreen`, `RecurringScreen`, and `StatisticsScreen`, and verifying all filter chips scroll horizontally without overflow bars.

**Acceptance Scenarios**:

1. **Given** filter chip bars in `LoanScreen`, `RecurringScreen`, and `StatisticsScreen`, **When** rendered on any screen width, **Then** they are enclosed in `SingleChildScrollView(scrollDirection: Axis.horizontal)` with uniform 8dp item spacing.

---

### User Story 3 - Unify Cards, Modals, and Clean Modern Styling (Priority: P2)

As a user interacting with cards, dialogs, and bottom sheets across the app, I want all cards to use consistent 16dp rounded corners with subtle 0.2 opacity borders, and all bottom sheets to use 20dp top rounded corners with proper keyboard-insets padding.

**Why this priority**: Enhances visual polish and eliminates jarring differences between newly added features and legacy screens.

**Independent Test**: Can be validated by opening bottom modals in Categories, Loans, Recurring, and Settings to ensure `Radius.circular(20)` top radius and consistent padding.

**Acceptance Scenarios**:

1. **Given** modal sheets across `CategoryBudgetScreen`, `LoanScreen`, and `RecurringScreen`, **When** opened, **Then** they consistently use `RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))`.
2. **Given** cards in `SettingsScreen` and `DashboardScreen`, **When** displayed, **Then** they adhere to `16dp` border radius and subtle border styling.
3. **Given** color opacity declarations across all screens, **When** compiled, **Then** all deprecated `.withOpacity(...)` calls are replaced with `.withValues(alpha: ...)`.

---

## Success Criteria *(mandatory)*

1. **100% Design System Adherence**: All 9 screens pass the checklist defined in `docs/design_system/screen_audit.md`.
2. **Zero RenderFlex Overflows**: No horizontal or vertical layout overflow exceptions anywhere in the app.
3. **Zero Deprecation Warnings**: All `.withOpacity()` usages migrated to `.withValues(alpha: ...)`.
4. **All Unit Tests Pass**: All existing unit tests continue to pass 100%.
