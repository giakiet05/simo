# Research: Streamline Transaction Form

## 1. Ergonomic Form Layout for Financial Entry

### Context
In personal finance applications, transaction entry is the highest-frequency task (often 3-10 times daily). The legacy implementation relied on a vertical sequence of dropdown form fields (`DropdownButtonFormField`), which required multiple clicks to open, scroll through, and select categories/wallets, followed by a separate modal pop-up for the custom calculator keypad.

### Decision
Adopt a modern, high-ergonomics two-tier layout:
- **Upper Section (Context & Display)**:
  - Prominent Type Toggle: Expense / Income segmented pill bar with high-contrast indicator.
  - Large Live Amount Display: Prominently shows the evaluated total with live thousand separators, formula preview (when math operators are active), and current currency symbol.
  - Context Chips Row: Fast selection for Wallet (with icon and current balance) and Date (shortcuts: "Today", "Yesterday", and calendar picker).
  - Optional Note Input: Inline, single-line/expandable with clear button.
- **Lower Section (Action & Input)**:
  - Embedded Visual Category Selector: A clean icon grid (or scrollable categorized chip grid) where categories are displayed with their distinct icons and colors for one-tap selection.
  - Dedicated `CustomNumPad`: Retain the full custom calculator keypad (0-9, 000, +, -, *, /, =, backspace, and Done/Save) directly accessible at the bottom of the screen.

### Rationale
- Eliminates modal hopping: Users don't need to tap a field to open a separate sheet for the calculator and then dismiss it to pick a category.
- Drastically cuts tap count: 1 tap for type, direct taps on the calculator, 1 tap on the category grid, and tap Save.
- Preserves the beloved `CustomNumPad` with all its existing formula evaluation logic and instant `000` multiplier.

### Alternatives Considered
- *Native System Keyboard*: Rejected. Standard OS keyboards lack the `000` quick key, instant arithmetic operators, and require opening an external calculator app for receipt splitting.
- *Modal Popups for Everything*: Rejected. Caused visual disorientation and slow multi-step entry in the legacy implementation.

---

## 2. Category Grid Architecture

### Context
Users typically have 10-25 categories. Displaying them in a dropdown hides visual visual cues (icons and colors) and requires scrolling through a tiny popup menu.

### Decision
Implement a responsive `CategoryGridPicker` widget:
- Displays categories as circular icon buttons with subtle background tint and localized labels below.
- 4-column layout on standard mobile screens with smooth vertical scrolling or pagination.
- Selected state highlighted with a bold primary border or scale animation.
- Automatically re-filters the category list when switching between Expense and Income tabs without clearing user-entered amounts.

### Rationale
- Recognitional UI over recall UI: Users spot familiar category icons (e.g. coffee cup for food, car for transport) in milliseconds without reading text.
- Reuses existing `CategoryIconWidget` for 100% visual consistency with the rest of the application.

### Alternatives Considered
- *Horizontal Carousel*: Rejected because horizontal carousels hide 70% of categories off-screen, forcing tedious swiping.

---

## 3. Preservation of CustomNumPad & Formula Engine

### Context
The user explicitly clarified: "vẫn giữ nguyên bàn phím custom ko? tao rất thích bàn phím đó, vì nó tiện" (Keep the custom keyboard 100% because it is very convenient).

### Decision
Reuse and seamlessly integrate `CustomNumPad`:
- Keep all numeric buttons (`0..9`, `000`, `.`).
- Keep arithmetic operators (`+`, `-`, `*`, `/`).
- Keep instant expression evaluation with proper order of operations.
- Ensure the layout is responsive to different screen heights using `Expanded` and `Flexible` constraints to avoid any yellow-black RenderFlex overflow.

### Rationale
- Zero learning curve for existing users.
- Retains key productivity features like typing `50` + `000` + `+` + `15` + `000` to quickly calculate shared meal costs.

---

## 4. Edit Mode & Multi-Add Experience

### Context
In Edit mode, the user is modifying an existing single transaction. In Add mode, power users may want to input multiple receipts consecutively ("Save & Add Another").

### Decision
- **In Edit Mode**:
  - Show "Edit Transaction" in AppBar.
  - Pre-fill existing amount, category, wallet, note, and date.
  - Provide an "Original Date" chip to quickly revert date changes.
  - Show a single "Save Changes" button.
- **In Add Mode**:
  - Provide both "Save" (saves and closes) and "Save & Add Another" (saves current record, clears amount and note, but retains selected wallet and date for the next entry).

### Rationale
- Replaces the legacy messy nested-card list in `TransactionFormScreen` with a clean, focused single-record screen that still empowers rapid batch entry via continuous logging.
