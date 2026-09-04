# Feature Specification: Features Hub Screen on Bottom Navigation Bar (Màn hình Chức năng)

**Feature Branch**: `013-features-hub-tab`

**Created**: 2026-09-03

**Status**: Draft

**Input**: User description: "nghiên cứu thay thế cái chỗ sổ nợ trên bottom bar nè. tao nghĩ nó nên thay bằng một mục tên là Chức năng, trong đó sẽ chứa các chức năng mình thấy trên truy cập nhanh, nhưng nên có gì đó khác biệt để ko bị copy cái menu tính năng lại. /speckit-specify lên danh sách tính năng"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Replace Bottom Bar Tab with "Chức năng" Hub (Priority: P1) 🎯 MVP

As a user navigating the app via the bottom navigation bar, I see a "Chức năng" (Features) tab in place of the standalone "Sổ nợ" tab. Tapping this tab opens a dedicated, well-organized Features Hub screen displaying all core financial tools.

**Why this priority**: Elevated structural navigation that provides a permanent home for all management modules without overcrowding the bottom bar.

**Independent Test**: Tap the 4th tab on the bottom navigation bar; verify it highlights "Chức năng" with an intuitive icon (`Icons.grid_view_rounded`) and opens the Features Hub screen.

**Acceptance Scenarios**:
1. **Given** user is on any screen, **When** tapping the 4th bottom navigation bar item, **Then** the app switches to the "Chức năng" screen.
2. **Given** user is on the "Chức năng" screen, **When** pressing the Android back button, **Then** the app navigates back to the Dashboard (tab 0).

---

### User Story 2 - Actionable Tool Cards with Live Previews (Priority: P1)

As a user exploring the "Chức năng" screen, I see feature cards that are distinct from simple dashboard shortcuts: each card displays real-time live status summaries (such as wallet count, budget remaining, next recurring due, loan totals, and top saving goal progress) along with immediate 1-tap quick action buttons.

**Why this priority**: Eliminates redundancy with Dashboard's Quick Access by providing rich, actionable information before the user even enters the detail screens.

**Independent Test**: View the Features screen with populated mock data; verify each tool card displays live figures and that tapping quick action buttons triggers modals or direct views.

**Acceptance Scenarios**:
1. **Given** user has active wallets, **When** viewing the "Ví tiền" card, **Then** it shows the count of active wallets, default wallet balance, and direct buttons for "Chuyển tiền" and "Thêm ví".
2. **Given** user has a monthly budget, **When** viewing the "Ngân sách" card, **Then** it displays spent percentage and remaining funds with an alert color if near/over budget.
3. **Given** user has debts or loans, **When** viewing the "Sổ nợ" card, **Then** it summarizes total borrowed and total lent amounts with a "+ Ghi nợ" shortcut.
4. **Given** user has saving goals, **When** viewing the "Mục tiêu" card, **Then** it shows the progress bar of the nearest saving goal.
5. **Given** user has recurring transactions, **When** viewing the "Định kỳ" card, **Then** it displays the date and name of the next upcoming transaction.

---

### User Story 3 - Categorized Workspace Sections (Priority: P2)

As a user wanting to find secondary tools, I can scroll through organized sections:
- **Dòng tiền & Tài sản**: Ví tiền, Giao dịch định kỳ.
- **Kế hoạch tài chính**: Ngân sách tháng & danh mục, Mục tiêu tích lũy.
- **Đối soát & Báo cáo**: Sổ nợ, Thống kê & Phân tích chuyên sâu.
- **Dữ liệu & Cấu hình**: Quản lý danh mục thu/chi, Xuất báo cáo (Excel/PDF/CSV), Sao lưu & Phục hồi.

**Why this priority**: Creates a scalable structure to house advanced tools that cannot fit on the main dashboard.

**Independent Test**: Scroll down the screen; verify all 4 grouped sections have clear headers, consistent spacing, and smooth scrolling without clipping.

**Acceptance Scenarios**:
1. **Given** user scrolls down, **When** reaching the "Dữ liệu & Cấu hình" section, **Then** tools for "Quản lý danh mục", "Xuất file báo cáo", and "Sao lưu" are clearly accessible.

---

## Edge Cases

- What happens if the user has no wallets, budgets, loans, or goals configured yet? The cards display clean onboarding empty states (e.g., "Chưa có ngân sách", "Chưa có khoản nợ") with invitation buttons to create one.
- What happens if privacy mode is active (`isHidden`)? All monetary values inside live preview cards are masked with bullets (`••••••••`).
- What happens on small screen sizes? Cards use responsive auto-scaling and flex layouts so live summaries never clip or overflow.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Bottom navigation bar MUST replace the "Sổ nợ" tab item with "Chức năng" (`Icons.grid_view_rounded` or `Icons.widgets_outlined`).
- **FR-002**: "Chức năng" screen MUST integrate with Riverpod providers (`walletProvider`, `monthlyBudgetProvider`, `loanProvider`, `savingGoalProvider`, `recurringProvider`) to fetch live summary metrics.
- **FR-003**: The screen MUST support privacy masking consistent with `isBalanceHidden` state.
- **FR-004**: Each primary tool card MUST provide a direct primary tap target to open its full management screen, as well as secondary quick-action buttons where applicable.
- **FR-005**: All monetary amounts displayed across tool cards MUST use comma `,` thousands separators (`#,###`).
- **FR-006**: The screen MUST include full localization support for Vietnamese and English.

---

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: 100% of tool cards display live real-time status data matching underlying database state within 300ms of tab switch.
- **SC-002**: Zero UI duplication with Dashboard Quick Access — each feature card provides at least 2 lines of contextual live data or sub-actions.
- **SC-003**: 0 layout overflow errors across various device resolutions (from 360dp to 480dp widths).
