# Contract: UI Refactoring Requirements

**Feature**: `007-align-app-design-system`

## Refactoring Contracts

### 1. AppBar Contract
- `elevation: 0`
- No hardcoded / mismatched `backgroundColor: ...inversePrimary`
- Right-hand action button: `IconButton(icon: const Icon(Icons.add), tooltip: l10n.add, onPressed: ...)`

### 2. Filter Chips Contract
- Wrap inside `SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(...))` with 8dp spacing

### 3. BottomSheet Modal Contract
- `shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))`

### 4. Deprecation Contract
- Zero `.withOpacity(...)` calls in `lib/` (use `.withValues(alpha: ...)` exclusively)
