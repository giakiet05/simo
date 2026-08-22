# Research: Design System & UI Architecture

**Feature**: `006-design-system-guidelines`

## 1. Documentation Structure Decision

- **Decision**: Organize the design system into modular, topic-specific markdown files in `docs/design_system/`:
  - `docs/design_system/README.md`: Introduction, design philosophy, and quick table of contents.
  - `docs/design_system/tokens.md`: Colors, typography, spacing, corner radii, elevation, dark/light mode pairs.
  - `docs/design_system/components.md`: Reusable UI patterns, AppBars, cards, modals, chips, forms, inputs, buttons, and empty states.
  - `docs/design_system/screen_audit.md`: Screen-by-screen audit matrix checking adherence of all existing screens.
  - `docs/design_system/recipes.md`: Ready-to-use boilerplate templates for new feature screens.
- **Rationale**: Keeps documentation clean, readable, and easy to maintain as the app scales.

---

## 2. Harmonization & Core Rules Extracted from Codebase

- **AppBar Action Rule**: Primary creation actions (e.g. `+` create) are placed in the top-right `actions` array of `AppBar` for consistency, keeping the bottom area clean for banner ads.
- **Card Aesthetics**: Flat elevation (`elevation: 0`) with 16dp/20dp rounded corners and subtle border `side: BorderSide(color: Colors.grey.withValues(alpha: 0.2))` to provide modern, lightweight visual separation.
- **Overflow-Proof Filters**: All horizontal filter chip rows must be enclosed in `SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(...))` to prevent horizontal RenderFlex overflows across different device widths and localized languages.
- **Currency Input Standard**: All monetary inputs must use `TextInputType.number`, comma thousands grouping (`CurrencyInputFormatter`), trailing currency symbol, and clean string parsing (`.replaceAll(',', '').trim()`).
- **Banner Ad Integration**: Screens embed `const BannerAdWidget()` at the bottom inside a `Column` with `Expanded` body.
