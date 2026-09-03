# Research & Decisions: Wallet UI & UX Refinements

**Feature**: `010-wallet-ui-refinements`
**Date**: 2026-09-03

## 1. Dynamic Net Worth Color Palette

### Decision
Apply financial status colors dynamically to the Net Worth Hero card:
- **Positive / Zero Net Worth ($\ge 0$)**: Emerald Green Gradient (`#059669` to `#10B981` in light mode, `#065F46` to `#047857` in dark mode).
- **Negative Net Worth ($< 0$)**: Crimson Alert Gradient (`#DC2626` to `#EF4444` in light mode, `#991B1B` to `#B91C1C` in dark mode).

### Rationale
- Gives immediate, intuitive visual feedback on personal financial solvency.
- Aligns with standard accounting visual conventions (Green = Asset / Positive, Red = Debt / Negative).

---

## 2. Dashboard Header De-cluttering

### Decision
Remove the inline `[Chuyển tiền]` and `[Ví tiền]` buttons from `DashboardNetWorthCard`.
- Keep only:
  - Header row: Wallet icon, Title ("TỔNG TÀI SẢN"), and Privacy Toggle Eye button.
  - Value row: Big bold formatted balance or `••••••••`.
- Navigation to transfers and all wallets is already provided directly by:
  - `MiniWalletCarousel` (1-tap to any wallet statement + "Quản lý" header button + "Thêm ví" card).
  - `QuickAccessHub` (Dedicated "Ví tiền" button).

### Rationale
- Reduces visual clutter and button duplication on the main landing screen.
- Makes the top hero card cleaner, more compact, and elegant.

---

## 3. Wallets Screen Header Unification

### Decision
Remove the duplicate `[Chuyển tiền]` and `[Thêm ví]` buttons from inside the Hero overview card in `WalletsScreen`.
- Retain the top-right AppBar action icons (`IconButton(icon: Icon(Icons.swap_horiz))` and `IconButton(icon: Icon(Icons.add))`).

### Rationale
- Removes duplicate touch targets on the same screen.
- Follows standard Material 3 / iOS navigation ergonomics where primary screen actions live in the top bar.

---

## 4. Robust `WalletCard` Layout for Long Names & Large Balances

### Decision
Redesign the row layout in `WalletCard`:
- Left: Squircle Icon (48x48dp fixed).
- Middle: Flexible Column containing:
  - Wallet Name: `maxLines: 2`, `overflow: TextOverflow.ellipsis`, `softWrap: true`
  - Default / Exclude Badge + Account Type Label
- Right: Amount & Popup Menu Column:
  - Amount text formatted with proper font weight, minimum width constraint, and `FittedBox(fit: BoxFit.scaleDown)` or `maxLines: 1`
  - Popup menu button

### Rationale
- Guarantees wallet names with 30-50 characters are never truncated to 1-2 letters, even when balance is over 100 billion VND (`100.000.000.000 ₫`).
