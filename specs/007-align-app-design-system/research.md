# Research: App-wide UI Alignment & Refactoring

**Feature**: `007-align-app-design-system`

## 1. Key Technical Decisions

### Decision 1: Uniform AppBar Standard
- **Action**: Remove any custom `backgroundColor: Theme.of(context).colorScheme.inversePrimary` from `RecurringScreen`, `LoanScreen`, and `CategoryScreen`. Set `elevation: 0`.
- **Action**: Replace bulky `Container(decoration: ..., TextButton.icon)` in `RecurringScreen` with standard `IconButton(icon: const Icon(Icons.add), tooltip: l10n.add, onPressed: ...)`.
- **Rationale**: Guarantees visual harmony across all screens and matches `SavingGoalsScreen` & `CategoryBudgetScreen`.

### Decision 2: Horizontal Overflow Elimination
- **Action**: Wrap all horizontal chip lists in `SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(...))` in `LoanScreen`, `RecurringScreen`, and `StatisticsScreen`.
- **Rationale**: Eliminates `RenderFlex overflow` on small screens or localized text variants.

### Decision 3: Modern Color API Migration
- **Action**: Replace all deprecated `.withOpacity(val)` with `.withValues(alpha: val)`.
- **Rationale**: Eliminates Flutter analyzer deprecation warnings and prevents precision loss during color conversions.

### Decision 4: BottomSheet Radii Standardization
- **Action**: Enforce `Radius.circular(20)` top radius on all modal bottom sheets across the app.
- **Rationale**: Matches the 20dp standard defined in `docs/design_system/tokens.md`.
