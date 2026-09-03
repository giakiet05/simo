# UI State & Layout Models: Wallet UI & UX Refinements

**Feature**: `010-wallet-ui-refinements`
**Date**: 2026-09-03

## 1. UI Presentation States

### 1.1 Net Worth Card Presentation
Computed presentation attributes based on `totalNetWorth`:

| Field | Type | Description |
| :--- | :--- | :--- |
| `isNegative` | `bool` | `totalNetWorth < 0` |
| `primaryGradientStart` | `Color` | `#059669` (if $\ge 0$) or `#DC2626` (if $< 0$) |
| `primaryGradientEnd` | `Color` | `#10B981` (if $\ge 0$) or `#EF4444` (if $< 0$) |
| `shadowColor` | `Color` | Tinted glow matching the gradient |

---

### 1.2 `WalletCard` Layout Model

```text
[ Squircle Icon ] [ Wallet Name (up to 2 lines)    ] [ Balance (scaleDown) ] [ Menu ]
 (48x48dp fixed)   [ Type • Badges                  ]
```
