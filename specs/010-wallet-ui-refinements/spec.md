# Feature Specification: Wallet UI & UX Refinements (Tinh chỉnh & Tối ưu Giao diện Ví tiền)

**Feature Branch**: `010-wallet-ui-refinements`

**Created**: 2026-09-03

**Status**: Draft

**Input**: User description: "một số góp ý của tao để chỉnh sửa: 1. trong màn hình chính, khi tổng tài sản âm thì cái widget nền đỏ, dương thì xanh. 2. Trong màn hình chính, theo tao ko cần nút chuyển tiền và tất cả ví, đang bị spam nhiều quá 3. vào màn hình tất cả ví, vừa có nút chuyển tiền và thêm ví mới, vừa có 2 nút tương ứng trên góc phải, cân nhắc bỏ 1 chỗ, theo tao để đồng bộ thiết kế thì giữ 2 nút góc trên phải. 4. vẫn trong màn hình tất cả ví, nếu số tiền quá dài, sẽ ẩn mất tên ví, cần có cơ chế để tên ví luôn phải hiển thị đầy đủ."

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Dynamic Hero Background & Clean Dashboard Header (Priority: P1)

Users see the Net Worth Hero Card on the Dashboard visually indicate their financial health through dynamic colors: Emerald Green gradient when Net Worth is positive or zero ($\ge 0$), and Warning Red/Crimson gradient when Net Worth is negative ($< 0$). The card is uncluttered by removing redundant inline action buttons, keeping the header clean and focused.

**Why this priority**: Directly addresses user visual clarity and cleans up redundant button spam on the main Dashboard.

**Independent Test**: Open Dashboard with positive Net Worth; verify Emerald Green background. Create negative balance (or credit card debt exceeding cash); verify card turns Crimson Red. Verify no redundant inline transfer/wallets buttons clutter the card.

**Acceptance Scenarios**:

1. **Given** user has Total Net Worth $\ge 0$, **When** viewing Dashboard, **Then** the Net Worth Hero card displays an Emerald Green gradient with white text.
2. **Given** user has Total Net Worth $< 0$, **When** viewing Dashboard, **Then** the Net Worth Hero card displays a Crimson Red alert gradient with white text.
3. **Given** the Net Worth Hero card on Dashboard, **When** examining its contents, **Then** it contains only the title, privacy eye toggle, and aggregate amount, without redundant inline transfer/wallets action buttons.

---

### User Story 2 - Clean Wallets Screen Hero Card without Duplicate Buttons (Priority: P1)

Users navigating to the Wallets Screen see a clean Net Worth summary card at the top. Redundant inline `[Chuyển tiền]` and `[Thêm ví]` buttons inside the Hero card are removed, preserving only the standard AppBar action icons in the top-right corner to keep the layout unified and elegant.

**Why this priority**: Eliminates UI duplication and aligns WalletsScreen with standard AppBar interaction patterns across the SIMO app.

**Independent Test**: Open Wallets Screen; verify top-right AppBar contains Transfer and Add Wallet icons, and the Hero overview card contains only the title, wallet counter, and total net worth without duplicate inline buttons.

**Acceptance Scenarios**:

1. **Given** user is on Wallets Screen, **When** looking at the top Hero card, **Then** it displays only Net Worth and total wallet count without inline action buttons.
2. **Given** user wants to add a wallet or transfer money, **When** tapping the top-right AppBar icons, **Then** the corresponding modals open smoothly.

---

### User Story 3 - Robust Wallet Card Layout for Long Currency Amounts & Long Names (Priority: P1)

Users with long wallet names (e.g. "Tài khoản Doanh nghiệp Techcombank VIP") and large balances (e.g. `120.000.000.000 ₫`) can clearly read both the entire wallet name and the complete amount without text truncation, layout clipping, or visual overflow.

**Why this priority**: Prevents critical financial information (account identity and balance numbers) from being hidden when figures or titles are lengthy.

**Independent Test**: Create a wallet with a 30+ character name and a 100+ billion VND balance; open Wallets Screen and verify the wallet name is fully legible and the balance is neatly formatted without overlapping or clipping.

**Acceptance Scenarios**:

1. **Given** a wallet with a long name and large balance, **When** viewed in Wallets Screen, **Then** the wallet name wraps gracefully or allocates proper flexible layout width so that the entire name remains fully visible.
2. **Given** compact mobile screen widths, **When** rendering wallet cards, **Then** no pixel overflow errors occurs and all badge chips (e.g. "Mặc định", "Không tính vào tổng") remain aligned.

---

### Edge Cases

- **Zero Balance**: Treated as positive (Emerald Green background).
- **Extreme Currency Length (> 15 digits)**: Balance text scales down or wraps neatly to prevent horizontal overflow.
- **Privacy Masking (`••••••`)**: When masked, dynamic colors still reflect the underlying state while hiding numeric values.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Dashboard Net Worth card MUST render an Emerald Green gradient when Net Worth is $\ge 0$, and a Crimson Red gradient when Net Worth is $< 0$.
- **FR-002**: Dashboard Net Worth card MUST NOT display inline buttons for transfer and all wallets.
- **FR-003**: Wallets Screen Net Worth overview card MUST render Emerald Green when $\ge 0$ and Crimson Red when $< 0$, without inline duplicate action buttons.
- **FR-004**: Wallets Screen MUST maintain Transfer and Add Wallet action icons exclusively in the top-right AppBar.
- **FR-005**: WalletCard MUST ensure the full wallet name is always visible and never cut off by large balance figures, using responsive flexible layout and multiline text wrapping where appropriate.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Immediate visual recognition (< 0.5s) of negative vs positive net worth through distinct color themes.
- **SC-002**: 100% removal of duplicate action buttons across Dashboard Hero and Wallets Screen Hero.
- **SC-003**: 100% of wallet names (up to 50 characters) and currency amounts (up to 18 digits) are fully readable on all mobile screen widths (360dp - 480dp) without overflow.

## Assumptions

- Riverpod state providers and localization providers are already in place and functioning.
- Existing wallet CRUD and transfer capabilities remain unchanged.
