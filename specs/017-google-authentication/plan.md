# Implementation Plan: Google Authentication & Cross-Platform Sessions

**Branch**: `017-google-authentication` | **Date**: 2026-09-13 | **Spec**: [`spec.md`](spec.md)

**Input**: Feature specification from [`specs/017-google-authentication/spec.md`](spec.md)

---

## Summary

Implement full cross-platform **Google Authentication (OAuth 2.0 / OIDC)** across the entire Simo ecosystem:
1. **Go Backend API (`apps/server`)**: Add Google ID Token validation service, PostgreSQL `users` table upserting logic, 30-day HMAC-SHA256 JWT session issuance, and `/api/v1/auth/google` & `/api/v1/auth/me` endpoints.
2. **React Web Frontend (`apps/web`)**: Integrate Google Identity Services (GIS) / `@react-oauth/google`, provide a sleek Login screen, manage global `AuthContext`, persist JWT session in `localStorage`, and display user avatar/profile in the top Navbar with a Sign-Out action.
3. **Flutter Mobile App (`apps/mobile`)**: Integrate `google_sign_in`, implement `AuthProvider` / `AuthService`, securely persist JWT tokens, link guest-created transactions to the authenticated user UUID, and auto-sync on login.

---

## Technical Context

**Language/Version**:
- Backend: Go 1.24+ (standard library `net/http` router, `crypto`, `github.com/golang-jwt/jwt/v5`)
- Mobile: Flutter 3.47+ / Dart 3.13 (`google_sign_in`, `flutter_riverpod`, `shared_preferences`)
- Web: TypeScript 5.x / React 19 / Vite (`@react-oauth/google` / GIS)

**Primary Dependencies**:
- Backend: `github.com/jackc/pgx/v5`, `github.com/golang-jwt/jwt/v5`, `github.com/google/uuid`
- Mobile: `google_sign_in: ^6.2.2`, `flutter_riverpod: ^2.6.1`
- Web: `@react-oauth/google: ^0.12.1`, `lucide-react`, `tailwindcss`

**Storage**:
- PostgreSQL `users` table on Homeserver (`id UUID`, `email`, `google_id`, `display_name`, `avatar_url`)
- Client: `localStorage` on Web, `SharedPreferences` / SecureStorage on Mobile

**Testing**:
- Go Backend: `go test -v ./internal/service/... ./internal/handler/...`
- Web Frontend: `npm run build` (strict TypeScript validation)
- Mobile App: `flutter test`

---

## Constitution Check

- [x] **Top 1 Priority for Go**: Backend token verification & user upserting built cleanly with Go standard library + `golang-jwt`.
- [x] **No hardcoded secrets**: `GOOGLE_CLIENT_ID` and `JWT_SECRET` loaded strictly from `.env`.
- [x] **Layered Architecture**: `Router` $\rightarrow$ `AuthHandler` $\rightarrow$ `AuthService` $\rightarrow$ `UserRepository` $\rightarrow$ `PostgreSQL`.
- [x] **Zero Fluff & Test First**: Comprehensive unit and mock token tests for Google ID Token verification.
- [x] **Offline-First Preservation**: Authentication state is cached locally; offline app launch remains 100% functional.

---

## Project Structure & Planned Changes

```text
simo/
├── apps/
│   ├── server/
│   │   ├── internal/
│   │   │   ├── config/
│   │   │   │   └── config.go             # [MODIFY] Add GoogleClientID, DevAuthBypass
│   │   │   ├── model/
│   │   │   │   └── auth.go               # [NEW] Auth DTOs (GoogleAuthRequest, AuthResponse)
│   │   │   ├── repository/
│   │   │   │   └── user_repo.go          # [NEW] UpsertUserByGoogleID, GetUserByID
│   │   │   ├── service/
│   │   │   │   └── auth_service.go       # [NEW] VerifyGoogleToken, IssueJWT
│   │   │   ├── handler/
│   │   │   │   └── auth_handler.go       # [NEW] GoogleAuth, GetMe
│   │   │   └── router/
│   │   │       └── router.go             # [MODIFY] Register /api/v1/auth/google & /me
│   │   └── .env.example                  # [MODIFY] Add GOOGLE_CLIENT_ID example
│   │
│   ├── web/
│   │   ├── src/
│   │   │   ├── contexts/
│   │   │   │   └── AuthContext.tsx       # [NEW] React Auth context & token persistence
│   │   │   ├── pages/
│   │   │   │   └── Login.tsx             # [NEW] Google Login Screen with GIS button
│   │   │   ├── components/
│   │   │   │   └── Navbar.tsx            # [MODIFY] Display Google Avatar, Name, Logout
│   │   │   ├── services/
│   │   │   │   └── api.ts                # [MODIFY] Add auth endpoints & dynamic headers
│   │   │   └── App.tsx                   # [MODIFY] Protect routes based on Auth state
│   │   └── package.json                  # [MODIFY] Add @react-oauth/google
│   │
│   └── mobile/
│       ├── lib/
│       │   ├── models/
│       │   │   └── user_profile.dart     # [NEW] User profile model
│       │   ├── providers/
│       │   │   └── auth_provider.dart    # [NEW] Riverpod AuthNotifier
│       │   ├── services/
│       │   │   └── auth_service.dart     # [NEW] GoogleSignIn wrapper & token exchange
│       │   └── screens/
│       │       └── settings_screen.dart  # [MODIFY] Google login card & profile view
│       └── pubspec.yaml                  # [MODIFY] Add google_sign_in
```

---

## Phased Execution Roadmap

### Phase 1: Go Backend Authentication Engine
1. Create [`auth.go`](../../apps/server/internal/model/auth.go) model DTOs.
2. Implement [`user_repo.go`](../../apps/server/internal/repository/user_repo.go) for PostgreSQL user provisioning.
3. Implement [`auth_service.go`](../../apps/server/internal/service/auth_service.go) with Google public key signature validation + mock bypass.
4. Implement [`auth_handler.go`](../../apps/server/internal/handler/auth_handler.go) and wire routes into [`router.go`](../../apps/server/internal/router/router.go).
5. Add unit tests for auth service and token validation.

### Phase 2: Web Management Authentication
1. Install `@react-oauth/google` in `apps/web`.
2. Implement `AuthContext` to manage token storage and user profile.
3. Build responsive `Login.tsx` screen with Dark theme and Google button.
4. Update `Navbar.tsx` to show Google user avatar, email, and Sign-Out button.
5. Verify end-to-end web login flow.

### Phase 3: Mobile Flutter Integration
1. Add `google_sign_in` to `apps/mobile/pubspec.yaml`.
2. Create `AuthService` and `AuthProvider` in Riverpod.
3. Update `SettingsScreen` with Google Account Card.
4. Wire `SyncService` to pass the authenticated JWT token.
5. Verify on Android / Linux runner.

### Phase 4: Verification & Docker Deployment
1. Rebuild backend & web containers via `docker compose up -d --build`.
2. Verify multi-tenant isolation with multiple test accounts.
