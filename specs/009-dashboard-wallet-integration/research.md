# Research & Architectural Decisions: Dashboard & Wallet Integration

**Feature**: `009-dashboard-wallet-integration`
**Date**: 2026-08-26

## 1. Dashboard Architectural Reorganization (Two-Tier Model)

### Decision
Structure the Dashboard into two clear, non-competing visual and logical layers:
1. **Tier 1 (Top / Global Snapshot)**: **Total Net Worth (Tổng tài sản) & Mini-Wallet Carousel**
   - Independent of the month selector dropdown.
   - Computes real-time aggregate of all active, non-excluded wallets (`exclude_from_total = 0`).
   - Hosts Privacy masking toggle (`••••••`) and rapid action buttons: `[Chuyển tiền]` (opens Transfer modal) and `[Ví tiền]` (navigates to Wallets screen).
   - Horizontal mini-wallet carousel below Hero card with squircle icons and 1-tap navigation to individual account statement views.
2. **Tier 2 (Bottom / Monthly Focus)**: **Monthly Cash Flow (Dòng tiền tháng) & Budgets**
   - Tied directly to the selected Month/Year dropdown.
   - Re-label the legacy "Số dư" (Balance) card to **"Dòng tiền tháng"** (or **"Thặng dư tháng"** when positive, **"Dòng tiền âm"** when negative) = `Monthly Income - Monthly Expense`.
   - Preserves existing Category Budgets, Spending Breakdown, and Recent Transactions.

### Rationale
- Eliminates user confusion between "How much money do I have in all accounts?" and "How much did I save this month?".
- Aligns with standard financial app best practices (e.g. MoneyForward, Toshl, Spendee, Copilot).

---

## 2. Privacy Mode State Management

### Decision
Use a lightweight Riverpod `StateProvider<bool>` for `isBalanceHiddenProvider` (default: `false` or persisted via `SharedPreferences`).
- When toggled, all currency amounts in the Top Hero card and Mini-Wallet carousel display masked characters (e.g. `••••••`).
- Toggle button uses `Icons.visibility` and `Icons.visibility_off`.

### Rationale
- Allows users to check the app in public without exposing total wealth or bank balances.
- Instant, non-blocking UI update via Riverpod.

---

## 3. Vietnamese Terminology & Localization Standardization

### Decision
Standardize all wallet and cashflow terminology in `lib/utils/localization.dart`:
- **Total Net Worth**: `Tổng tài sản`
- **Monthly Cash Flow**: `Dòng tiền tháng`
- **Monthly Surplus**: `Thặng dư tháng`
- **Monthly Deficit**: `Dòng tiền âm`
- **Internal Transfer**: `Chuyển tiền nội bộ` / `Chuyển tiền`
- **Wallets Overview**: `Ví tiền` / `Danh sách ví`
- **Account Types**:
  - `cash`: `Tiền mặt`
  - `bank`: `Tài khoản ngân hàng`
  - `ewallet`: `Ví điện tử`
  - `credit`: `Thẻ tín dụng`
  - `savings`: `Sổ tiết kiệm`
  - `other`: `Khác`
- **Initial Balance**: `Số dư ban đầu`
- **Exclude from Total**: `Không tính vào tổng tài sản`

### Rationale
- Resolves all user feedback regarding untranslated English strings and ensures consistent financial nomenclature.

---

## 4. Performance & Smooth Horizontal Scrolling

### Decision
Construct the Mini-Wallet Carousel using `SizedBox(height: ..., child: ListView.separated(...))` with `scrollDirection: Axis.horizontal` and `BouncingScrollPhysics`.
- Each card has fixed width (~150-160dp) with rounded squircle container, balance display, and tap feedback.
- If total wallets > 5, lazy rendering guarantees zero frame drops.

### Rationale
- Fast rendering on all Android/iOS devices without nested scroll conflict with the outer vertical scroll view.
