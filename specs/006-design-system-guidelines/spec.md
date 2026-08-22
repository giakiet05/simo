# Feature Specification: Design System & UI Guidelines Documentation

**Feature Branch**: `006-design-system-guidelines`

**Created**: 2026-08-22

**Status**: Draft

**Input**: User description: "giúp tao gom hết ngôn ngữ thiết kế của project này thành một file hoặc nhiều file trong 1 folder, tốt nhất là đặt vào docs. Để từ đó mình có thể đồng bộ lại các giao diện cho đồng bộ style và làm nên để làm thêm các màn hình khách trong tương lai"

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Core Design Tokens & Visual Hierarchy (Priority: P1)

As a developer and UI designer building features for Simo, I want a single source of truth for all design tokens (color palettes, typography scale, spacing rules, corner radii, elevation, dark/light mode pairs), so that every visual element adheres to the app's established design language.

**Why this priority**: Core tokens form the essential foundation for all components, screens, and future feature developments.

**Independent Test**: Can be validated by reviewing the core tokens documentation in `docs/design_system/tokens.md` against existing theme files (`lib/theme/app_colors.dart`, `lib/theme/app_theme.dart`) and confirming all color mappings, font hierarchies, and spacing values are accurately documented.

**Acceptance Scenarios**:

1. **Given** the documentation in `docs/design_system/tokens.md`, **When** a developer consults the document for color tokens, **Then** they can find exact hex codes and semantic usages for Primary, Secondary, Background, Surface, Income (Emerald), Expense (Red), Warning (Amber), Info (Sky), and the 10-color Category palette.
2. **Given** text styling guidelines, **When** building a new screen header or balance display, **Then** the typography scale explicitly defines font weights, sizes, and color contrast rules for both Light and Dark themes.
3. **Given** spacing and layout metrics, **When** designing screen paddings and margins, **Then** the standard 8dp grid system (4dp, 8dp, 12dp, 16dp, 20dp, 24dp) and corner radii standards (8dp for chips/tags, 12dp for inputs/buttons, 16dp-20dp for cards/modals) are clearly prescribed.

---

### User Story 2 - Reusable Component Patterns & Interaction Guidelines (Priority: P1)

As a developer adding or refining app screens, I want comprehensive component pattern guides (AppBars, Overview Summary Cards, Bottom Sheet Modals, Choice Chips, Currency Form Fields, Action Buttons, Empty States), so that user interactions and screen structures are completely unified across the app.

**Why this priority**: Standardized component patterns prevent UI fragmentation (e.g. inconsistent placement of add buttons, mismatched card paddings, unscrollable chip rows).

**Independent Test**: Can be validated by reviewing `docs/design_system/components.md` to ensure every core UI component has clear layout specs, code snippets/recipes, and rules for edge-case handling (e.g., overflow prevention).

**Acceptance Scenarios**:

1. **Given** the AppBar specification, **When** creating a sub-screen, **Then** it specifies `elevation: 0`, title text style, and placement of primary action buttons (like `+` create) strictly in the top-right `actions` array rather than floating action buttons.
2. **Given** the Currency Input pattern, **When** implementing an amount field, **Then** it specifies `TextInputType.number`, thousand comma formatting (`CurrencyInputFormatter`), trailing currency symbol, and input validation rules.
3. **Given** filter chip patterns, **When** rendering category or status filters, **Then** it prescribes wrapping rows in horizontal `SingleChildScrollView` to eliminate horizontal RenderFlex overflow bugs.
4. **Given** an empty state scenario, **When** no records exist in a list, **Then** it details the standard centered layout with circular soft-tint icon, bold title, description, and primary call-to-action button.

---

### User Story 3 - Existing Screen UI Audit & Alignment Matrix (Priority: P2)

As a developer maintaining the Simo codebase, I want an audit of all existing screens comparing their current implementation with the unified design system, so that any visual discrepancies can be systematically identified and refactored.

**Why this priority**: Bridges the gap between the documented design system and existing screens in the codebase.

**Independent Test**: Can be validated by reviewing `docs/design_system/screen_audit.md` and verifying that all main screens (Dashboard, Transactions, Loans, Monthly Budgets, Recurring, Statistics, Saving Goals, Export/Backup, Settings) are cataloged with their current style adherence status.

**Acceptance Scenarios**:

1. **Given** the audit documentation, **When** inspecting each screen in `lib/screens/`, **Then** the document highlights current UI patterns, strengths, and areas requiring harmonization.
2. **Given** a checklist of alignment items, **When** updating an existing screen, **Then** clear before/after guidelines ensure consistent style across all screens.

---

### User Story 4 - Future Screen Templates & UI Recipes (Priority: P3)

As a developer expanding the app with new capabilities, I want ready-to-use boilerplate templates and recipes for common screen archetypes (CRUD List Screen, Form BottomSheet, Master-Detail Screen, Analytics Dashboard), so that new features can be built rapidly without reinventing UI patterns.

**Why this priority**: Accelerates future development while guaranteeing design system compliance.

**Independent Test**: Can be validated by copying a boilerplate screen template from `docs/design_system/recipes.md` and verifying it compiles cleanly and conforms to all design system rules.

**Acceptance Scenarios**:

1. **Given** a requirement for a new entity management feature, **When** a developer follows the "CRUD List Screen Recipe", **Then** they get a fully functional scaffold with AppBar `+` button, Overview Card, Filter Chips, List Cards with progress/badges, and Bottom Banner Ad integration.

---

## Key Artifacts *(mandatory)*

- `docs/design_system/README.md`: Index and overview of the Simo Design System.
- `docs/design_system/tokens.md`: Design tokens (Colors, Typography, Spacing, Elevation, Radii, Dark/Light mode).
- `docs/design_system/components.md`: Reusable UI component specifications and patterns.
- `docs/design_system/screen_audit.md`: Screen-by-screen UI audit and style alignment checklist.
- `docs/design_system/recipes.md`: Boilerplate screen recipes and templates for future features.

---

## Success Criteria *(mandatory)*

1. **100% Comprehensive Coverage**: 100% of Simo's active UI patterns, colors, font sizes, modal conventions, and layout rules are documented.
2. **Zero Ambiguity for Developers**: Developers can build a brand new screen without guessing any margin, font size, color hex, or button placement.
3. **Actionable Refactoring Roadmap**: Clear screen audit identifying any legacy UI inconsistencies with steps to harmonize them.
4. **Developer-Friendly Documentation**: Well-structured Markdown documentation organized cleanly under `docs/design_system/`.
