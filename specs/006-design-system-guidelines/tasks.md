# Tasks: Design System & UI Guidelines Documentation

**Branch**: `006-design-system-guidelines` | **Spec**: [specs/006-design-system-guidelines/spec.md](spec.md) | **Plan**: [specs/006-design-system-guidelines/plan.md](plan.md)

## Phase 1: Setup

**Purpose**: Documentation structure initialization

- [x] T001 [P] Create `docs/design_system/` directory structure and write `docs/design_system/README.md` with system overview and table of contents

---

## Phase 2: User Story 1 - Core Design Tokens & Visual Hierarchy (Priority: P1) 🎯 MVP

**Goal**: Document the single source of truth for color palettes, typography scale, spacing, radii, elevation, and dark/light theme pairing.

**Independent Test**: Review `docs/design_system/tokens.md` against theme classes in `lib/theme/` and verify all tokens and values are documented accurately.

### Implementation for User Story 1
- [x] T002 [P] [US1] Write `docs/design_system/tokens.md` documenting Colors (Core, Semantic, Category palette), Typography scale, 8dp Grid Spacing, Corner Radii, Elevation, and Dark/Light Mode rules

**Checkpoint**: Core tokens are fully documented and established as project standards

---

## Phase 3: User Story 2 - Component Blueprints & Interaction Patterns (Priority: P1)

**Goal**: Document standardized patterns for AppBars, Cards, Filter Chips, Inputs, Buttons, Modals, Empty States, and Banner Ads.

**Independent Test**: Review `docs/design_system/components.md` to verify every core component has layout rules, edge-case handling (e.g. overflow prevention), and code snippets.

### Implementation for User Story 2
- [x] T003 [P] [US2] Write `docs/design_system/components.md` detailing AppBars, Overview Hero Cards, List Cards, Horizontal Filter Chips, Currency Formatting, Action Buttons, BottomSheet Modals, Empty States, and Banner Ads

**Checkpoint**: Component pattern library is fully documented

---

## Phase 4: User Story 3 - Screen-by-Screen UI Audit & Alignment Matrix (Priority: P2)

**Goal**: Audit all 9 existing screens in Simo and list concrete alignment recommendations.

**Independent Test**: Review `docs/design_system/screen_audit.md` and confirm all 9 screens are audited against the design system.

### Implementation for User Story 3
- [x] T004 [P] [US3] Write `docs/design_system/screen_audit.md` auditing all 9 screens (Dashboard, Transactions, Loans, Budgets, Recurring, Statistics, Saving Goals, Export/Backup, Settings) and noting harmonization actions

**Checkpoint**: Screen audit is complete with clear refactoring roadmap

---

## Phase 5: User Story 4 - Boilerplate Templates & Screen Recipes (Priority: P3)

**Goal**: Provide ready-to-use boilerplate templates for new feature screen development.

**Independent Test**: Review `docs/design_system/recipes.md` and verify all boilerplate Flutter code templates are compilable and follow design guidelines.

### Implementation for User Story 4
- [x] T005 [P] [US4] Write `docs/design_system/recipes.md` providing standard Flutter boilerplate templates for CRUD List Screens, Form BottomSheets, and Master-Detail Screens

**Checkpoint**: Screen recipes are ready for developers building future features

---

## Phase 6: Polish & Verification

**Purpose**: Cross-artifact verification

- [x] T006 Verify all documentation against `specs/006-design-system-guidelines/quickstart.md`
