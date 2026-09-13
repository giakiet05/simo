# Research & Architecture Decisions: Web UI Full Feature Parity

**Feature**: `018-web-ui-full-parity`
**Date**: 2026-09-13

## 1. UI Theme & Design System Architecture

### Decision
Implement a semantic CSS variable-driven Design System using Tailwind CSS v4. The default theme is **Crisp White Light Mode** (`background: #ffffff`, card surface: `#f8fafc`, border: `#e2e8f0`, text: `#0f172a`), with an instant toggle to **Slate Dark Mode** (`background: #020617`, card surface: `#0f172a`, border: `#1e293b`, text: `#f8fafc`).

### Rationale
- Aligns with the user's primary requirement: "ưu tiên nền trắng, có darkmode".
- White theme provides maximum clarity for dense financial tables, balance statements, and multi-parameter filters.
- Semantic CSS tokens (`bg-surface`, `border-card`, `text-primary`, `text-secondary`, `badge-income`, `badge-expense`) enable immediate 1-click theme switching (<50ms) across all pages without layout shifts or component re-renders.

### Alternatives Considered
- *Hardcoded Dark Mode only (current prototype)*: Rejected because the user specifically mandated white background priority with toggleable dark mode.
- *External CSS Component Libraries (Chakra / MUI / AntD)*: Rejected because they add heavy runtime overhead (~500KB+), duplicate styles, and conflict with Simo's clean minimalist aesthetic.

---

## 2. Client-Side State Management & Offline Storage

### Decision
Implement a lightweight, typed Reactive Financial Store combining React Contexts with browser **IndexedDB / LocalStorage** for offline caching, mirroring the 11-table SQLite architecture from the Android mobile app.

### Rationale
- **1:1 Parity**: Replicating the 11 entities locally (`wallets`, `wallet_transfers`, `categories`, `transactions`, `monthly_budgets`, `category_monthly_budgets`, `saving_goals`, `saving_goal_logs`, `loan_contacts`, `loan_transactions`, `recurring_configs` + `pending_deletions`) enables instant UI updates (Optimistic UI) before network roundtrips.
- **Offline Resilience**: Users on laptops or flaky Wi-Fi can log transactions, adjust budgets, and manage wallets offline; mutations are queued with `synced = 0` and auto-synchronized upon network recovery.

### Alternatives Considered
- *Direct Server-Only API calls on every click*: Rejected because it results in loading spinners on every action, fails when offline, and diverges from the mobile app's instant offline-first experience.
- *Redux Toolkit / MobX*: Rejected as unnecessarily heavy. React Context with a typed event-driven sync listener provides all needed capabilities with zero external dependencies.

---

## 3. Bidirectional Sync Engine on Web

### Decision
Implement a TypeScript `SyncService` in `apps/web` that implements the exact same sync protocol as the Flutter app and Go server:
- Timestamp-based incremental sync (`last_synced_server_time`).
- Mutations push payload containing all modified records with `synced = 0`.
- Deletions push payload containing tombstone records from `pending_deletions` (`cloud_id`, `table_name`, `deleted_at`).
- Pull changes merged into local store using Last-Write-Wins based on `server_time`.
- Debounced auto-sync trigger (800ms debounce) on any local mutation + instant sync on network reconnection (`window.addEventListener('online')`).

### Rationale
- Ensures 100% interoperability between the Android mobile app, the Go server, and the Web UI.
- Prevents data loss and ghost records across devices.

---

## 4. Visual Analytics & Charting

### Decision
Implement responsive SVG/Canvas interactive charts for:
1. **Donut / Pie Chart**: Category-based expense and income distribution with hover tooltips and category breakdown percentages.
2. **Bar & Line Cashflow Trends**: Monthly and daily income vs expense cashflow progressions over time.
3. **Budget Gauge & Linear Progress Bars**: Color-coded spending vs budget thresholds (<80% emerald, 80-100% amber, >100% rose).

### Rationale
- Lightweight SVG/Canvas charts provide fast rendering without heavy chart bundle bloat, maintaining the <1.2s FCP target.
- Full dark/light mode compatibility by utilizing CSS color tokens.

---

## 5. Export & Backup Engine (CSV, Excel, PDF, JSON)

### Decision
- **CSV Export**: Client-side generation using standard RFC 4180 UTF-8 formatted CSV with BOM for Vietnamese character compatibility in Microsoft Excel.
- **Excel (.xlsx) Export**: Structured multi-column workbook generation for financial statements.
- **PDF Export**: Print-optimized stylesheet (`@media print`) and vector PDF printable layout for clean financial receipts/statements.
- **JSON Backup & Restore**: Full 11-table database dump/import with pre-import inspection modal (counts of transactions, wallets, categories, etc.).

### Rationale
- Delivers 100% parity with the mobile app's export & backup capabilities directly in the browser without server processing bottlenecks.
