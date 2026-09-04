# Quickstart & Validation Guide: Features Hub Screen

**Feature**: `013-features-hub-tab`
**Date**: 2026-09-03

## 1. Validation Scenarios

### Scenario 1: Bottom Navigation Bar Integration
1. Launch SIMO.
2. Observe bottom navigation bar: 4th tab displays `Icons.grid_view_rounded` with label `Chức năng` (or `Features`).
3. Tap the 4th tab: verify it navigates to `FeaturesScreen` with an AppBar titled `Chức năng`.
4. Press Back button: verify it navigates back to Dashboard tab (index 0).

### Scenario 2: Live Status Cards & Section Browsing
1. On `FeaturesScreen`, view the 4 sections:
   - **Dòng tiền & Tài sản**: Wallets card with wallet count and default wallet balance; Recurring bills card.
   - **Kế hoạch Tài chính**: Budgets card with percentage badge; Saving goals card with progress.
   - **Đối soát & Thống kê**: Loans card with borrowed and lent totals; Statistics card.
   - **Dữ liệu & Tiện ích**: Categories card; Data Export card; Backup & Restore card.
2. Tap each card: verify it navigates directly to the target screen without errors.
3. Tap action buttons on cards (e.g. `+ Ghi nợ`, `Chuyển tiền`): verify modals open properly.
