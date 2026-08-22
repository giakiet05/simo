# Data Model: Design System & UI Specifications

**Feature**: `006-design-system-guidelines`

## Design System Hierarchy

```
docs/design_system/
├── README.md              # Overview, design principles, table of contents
├── tokens.md              # Colors, typography, spacing, radii, elevations
├── components.md          # Component blueprints & pattern library
├── screen_audit.md        # Comprehensive audit of existing screens
└── recipes.md             # Code templates for new screen development
```

## Core Token Definitions

| Category | Token Name | Value / Standard | Semantic Usage |
|----------|------------|------------------|----------------|
| **Color** | `AppColors.primary` | `#0F172A` (Slate 900) | AppBars, active states, key accents |
| **Color** | `AppColors.secondary` | `#3B82F6` (Blue 500) | Interactive buttons, charts |
| **Color** | `AppColors.income` | `#10B981` (Emerald 500) | Positive cash flow, deposit badges |
| **Color** | `AppColors.expense` | `#EF4444` (Red 500) | Spending, withdrawal badges, errors |
| **Color** | `AppColors.warning` | `#F59E0B` (Amber 500) | Near budget limit, warnings |
| **Color** | `AppColors.info` | `#0EA5E9` (Sky 500) | Informational tags, tips |
| **Radius** | `sm` | `8.0` | Badges, small chips, mini indicators |
| **Radius** | `md` | `12.0` | Text fields, action buttons, icon boxes |
| **Radius** | `lg` | `16.0` | Standard list item cards, dialogs |
| **Radius** | `xl` | `20.0` | Overview hero cards, BottomSheet modals |
| **Spacing**| `paddingScreen` | `16.0` | Standard outer horizontal padding |
| **Spacing**| `paddingCard` | `16.0 - 20.0` | Inner padding of summary/list cards |
| **Spacing**| `gapItems` | `8.0 - 12.0` | Spacing between list cards / form fields |
