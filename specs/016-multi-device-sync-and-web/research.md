# Technical Research & Architecture Decisions: Multi-Device Sync & Web

**Feature**: `016-multi-device-sync-and-web`
**Date**: 2026-09-12

---

## 1. Backend Language & Routing Framework

- **Decision**: Go (1.27+) using modern standard library `net/http` enhanced routing (or lightweight `go-chi/chi/v5`).
- **Rationale**: 
  - Aligns with the core tech stack rule (Go as Top 1 backend priority).
  - Modern Go `net/http` natively supports HTTP method routing and path pattern wildcards (e.g. `GET /api/v1/transactions/{id}`) without heavy framework lock-in.
  - Zero bloat, ultra-low memory footprint (<20MB RSS), instant startup time (<50ms).
- **Alternatives Considered**:
  - *Gin*: Popular but introduces external middleware conventions that are unnecessary given Go's modernized stdlib.
  - *Fiber*: Built on `fasthttp`, breaks standard `http.Handler` interoperability.

---

## 2. PostgreSQL Connection & Storage Layer

- **Decision**: `jackc/pgx/v5` connection pool with raw parametrized SQL / `pgxpool`.
- **Rationale**:
  - Top-tier performance in the Go ecosystem.
  - Direct support for batch operations, transactional isolation levels, and native PostgreSQL JSON/UUID/TIMESTAMPTZ types.
  - Reads connection strings strictly from environment variables (`DATABASE_URL` / `DB_HOST`, `DB_PORT`, `DB_USER`, `DB_PASSWORD`, `DB_NAME`).
  - Works out-of-the-box with existing containerized PostgreSQL on the user's homeserver.
- **Alternatives Considered**:
  - *GORM*: High abstraction overhead, hides SQL execution details, prone to N+1 queries during bulk sync upserts.
  - *sqlc*: Type-safe SQL compiler, very good option if SQL complexity grows, but simple handcrafted repository functions with pgx offer maximum transparency for sync logic.

---

## 3. Sync Protocol & Concurrency Mechanics

- **Decision**: Unified Single-Endpoint 2-Way Synchronization (`POST /api/v1/sync`) with **Push-First $\rightarrow$ Pull-Second** transactional pipeline.
- **Rationale**:
  - Single network roundtrip achieves complete convergence in <100ms.
  - Push-First acts as the conflict arbiter: client mutations are evaluated and merged into PostgreSQL before reading changes.
  - Pull-Second fetches authoritative server state for other devices.
  - Server assigns `server_updated_at = NOW() AT TIME ZONE 'UTC'` on every mutation, serving as the immutable cursor for client pulls.
  - Client wall-clock time is completely decoupled from sync filtering, making the engine immune to timezone disparities (US vs VN) and client clock skew.
  - Soft deletions (Tombstones with `deleted_at`) ensure deletions supersede stale updates.
- **Alternatives Considered**:
  - *Separate Push and Pull Endpoints*: Requires 2 HTTP requests per mutation event, increases latency and edge case window.
  - *CRDTs (Conflict-free Replicated Data Types)*: Unnecessary algorithmic complexity for a single-user multi-device personal finance tracker.

---

## 4. Web Frontend Architecture

- **Decision**: React + TypeScript + Vite + Tailwind CSS + TanStack Query (React Query).
- **Rationale**:
  - Ultra-fast initial page load (<500ms bundle load vs 15MB+ Flutter Web WASM).
  - Native desktop browser UX: crisp text rendering, effortless copy/paste, standard table sorting, and responsive layout.
  - TanStack Query provides out-of-the-box caching, background refetching, and optimistic updates.
- **Alternatives Considered**:
  - *Flutter Web*: High bundle size (~20MB), slow initial paint on desktop, non-native text selection and scrolling feel.
  - *Next.js (SSR)*: Added server runtime complexity; a static SPA served via Nginx/Caddy or Vercel talking directly to the Go API is more pragmatic.

---

## 5. Authentication & Security Strategy

- **Decision**: Stateless JWT (Access Token + Refresh Token) with Google OAuth 2.0 verification and standard Email/Password fallback.
- **Rationale**:
  - Ensures multi-tenant data isolation: all SQL queries enforce `WHERE user_id = $1`.
  - Secure and lightweight: mobile app and web frontend use identical Bearer token authentication headers.
