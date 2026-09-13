# Implementation Plan: Web UI Full Feature Parity with Android App

**Branch**: `018-web-ui-full-parity` | **Date**: 2026-09-13 | **Spec**: [spec.md](spec.md)

**Input**: Feature specification from `/specs/018-web-ui-full-parity/spec.md`

## Summary

Build a comprehensive, 1:1 feature-parity Web UI for Simo Personal Finance matching all functional modules and user flows of the Android mobile app. The web application is built with React 19, TypeScript, Vite, and Tailwind CSS v4, featuring a default crisp white light theme, dedicated dark mode toggle, full 11-table client-side financial store with IndexedDB/LocalStorage offline caching, and real-time bidirectional synchronization with the backend Go server.

## Technical Context

**Language/Version**: TypeScript 5.7+ / ECMAScript 2024 (React 19.x, Vite 8.x)

**Primary Dependencies**: React 19, Tailwind CSS v4, `@tanstack/react-query`, `lucide-react`, `@react-oauth/google`, `clsx`, `tailwind-merge`

**Storage**: Browser LocalStorage & IndexedDB for offline persistence; Go PostgreSQL backend via REST Sync API (`/api/sync`)

**Testing**: Oxlint, TypeScript type checks (`tsc -b`), browser unit/integration test harness

**Target Platform**: Modern Web Browsers (Chrome, Firefox, Safari, Edge) on Desktop, Tablet, and Mobile viewports

**Project Type**: Full-featured Single Page Web Application (`apps/web`)

**Performance Goals**: First Contentful Paint (FCP) < 1.2s; theme switch latency < 50ms; transaction filter response < 100ms for 5,000 items

**Constraints**: 100% offline-resilient; strict bidirectional sync compatibility with Android client schema (11 entities + pending deletions); zero third-party UI framework bloat

**Scale/Scope**: 10 complete modules (Dashboard, Transactions, Wallets, Categories, Budgets, Saving Goals, Loans, Recurring, Analytics & Reports, Settings & Export)

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

- [x] **Architecture Alignment**: Monorepo structure preserved (`apps/web`, `apps/mobile`, `apps/server`).
- [x] **Technical Standards**: 100% TypeScript, English-only codebase and internal comments, strict error handling, structured logging.
- [x] **Feature Parity**: Covers all 11 database entities and 10 UI modules from the mobile app.
- [x] **Theme Requirements**: Default crisp white light background with 1-click slate dark mode.

## Project Structure

### Documentation (this feature)

```text
specs/018-web-ui-full-parity/
├── plan.md              # Implementation plan
├── research.md          # Phase 0: Research & architecture decisions
├── data-model.md        # Phase 1: Data model & client store schema
├── quickstart.md        # Phase 1: End-to-end validation guide
├── contracts/           # Phase 1: API & service contracts
│   └── web-ui-contracts.md
├── checklists/
│   └── requirements.md
└── tasks.md             # Phase 2 output (/speckit-tasks command)
```

### Source Code (`apps/web`)

```text
apps/web/src/
├── components/          # Reusable UI components
│   ├── ui/              # Buttons, inputs, modals, cards, badges, theme toggle
│   ├── charts/          # Donut category chart, cashflow bar/line charts
│   ├── Navbar.tsx       # Top navigation bar with sync status & theme toggle
│   ├── Sidebar.tsx      # Desktop navigation sidebar
│   ├── TransactionModal.tsx # New / Edit transaction form modal
│   ├── WalletModal.tsx  # New / Edit wallet & transfer modal
│   ├── CategoryModal.tsx# New / Edit category modal
│   ├── BudgetModal.tsx  # Monthly & category budget configuration modal
│   ├── SavingGoalModal.tsx # Saving goal & deposit/withdraw modal
│   ├── LoanModal.tsx    # Loan contact & borrow/lend modal
│   └── RecurringModal.tsx # Recurring schedule configuration modal
├── contexts/            # Global application state
│   ├── AuthContext.tsx  # Google & session authentication
│   ├── ThemeContext.tsx # White Light / Slate Dark theme provider
│   └── FinanceContext.tsx # Unified financial reactive store
├── hooks/               # Custom hooks (filters, search, sync listener)
├── pages/               # Top-level page views
│   ├── Dashboard.tsx    # Financial overview & quick metrics
│   ├── Transactions.tsx # Filterable date-grouped transaction ledger
│   ├── Wallets.tsx      # Multi-wallet cards, statements & transfers
│   ├── Budgets.tsx      # Monthly & category spending budget tracker
│   ├── SavingGoals.tsx  # Saving goals cards & deposit logs
│   ├── Loans.tsx        # Loan contacts & repayment ledger
│   ├── Recurring.tsx    # Recurring transaction schedule manager
│   ├── Reports.tsx      # Category breakdown & cashflow analytics
│   ├── ExportBackup.tsx # CSV, Excel, PDF export & JSON backup/restore
│   └── Settings.tsx     # Currency, localization, theme & sync controls
├── services/            # API, Sync engine & export utilities
│   ├── api.ts           # REST API client
│   ├── syncService.ts   # Incremental bidirectional sync engine
│   ├── exportService.ts # CSV, Excel, PDF & JSON export generator
│   └── db.ts            # Client-side IndexedDB/LocalStorage adapter
└── types/               # TypeScript interfaces for all 11 entities
    └── index.ts
```

## Complexity Tracking

| Aspect | Decision | Simpler Alternative Rejected Because |
|---|---|---|
| Client Financial Store | Reactive Store with local caching | Server-only fetching causes network latency on every click and breaks offline functionality |
| Sync Engine | Bidirectional incremental sync with tombstones | Simple replace-all sync causes massive payload overhead and overwrites concurrent edits |
| Export Engine | Pure Client-side generation (CSV/Excel/PDF/JSON) | Backend export endpoints require file server storage and add latency |
