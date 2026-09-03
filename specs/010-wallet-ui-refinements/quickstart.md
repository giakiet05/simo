# Quickstart & Validation Guide: Wallet UI & UX Refinements

**Feature**: `010-wallet-ui-refinements`
**Date**: 2026-09-03

## 1. Validation Scenarios

### Scenario 1: Dashboard Dynamic Colors & Streamlined Header
1. Open Dashboard when Net Worth is positive. Verify top Hero card has an Emerald Green background.
2. Toggle privacy eye icon. Verify amount masks with `••••••••`.
3. Verify no inline `[Chuyển tiền]` or `[Tất cả ví]` buttons appear inside the Hero card.

### Scenario 2: Wallets Screen Hero Card Cleanup
1. Open Wallets Screen.
2. Verify top Hero card displays Net Worth and wallet count only, without inline action buttons.
3. Tap the `+` and `swap` icons in the top-right AppBar. Verify they open the Add Wallet and Transfer modals.

### Scenario 3: Long Wallet Name & Large Balance Display
1. Create a wallet with name "Ngân hàng Thương mại Cổ phần Ngoại thương Việt Nam VCB".
2. Set balance to `150,000,000,000`.
3. Open Wallets Screen.
4. Verify the entire name wraps and displays completely without being truncated or truncated to 1-2 letters.
