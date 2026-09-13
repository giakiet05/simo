# Research & Architecture Decisions: Google Authentication & Cross-Platform Sessions

**Feature**: `017-google-authentication` | **Date**: 2026-09-13

---

## 1. Technical Decisions

### Decision 1: Google ID Token Verification on Go Backend
- **Choice**: Direct verification using Google's public JWKS endpoint (`https://www.googleapis.com/oauth2/v3/certs` / `google.golang.org/api/idtoken` or lightweight cached key validator).
- **Rationale**:
  - Validates cryptographic signatures from Google without calling Google servers on every individual request.
  - Checks token claims: `aud == GOOGLE_CLIENT_ID`, `iss in ["accounts.google.com", "https://accounts.google.com"]`, and `exp > now`.
  - Zero heavy third-party dependencies; robust and standard across Go services.
- **Alternatives considered**:
  - *Google OAuth UserInfo Endpoint (`https://www.googleapis.com/oauth2/v3/userinfo`)*: Makes an external HTTP call per login. Slower and requires access tokens instead of ID tokens.
  - *Firebase Auth*: Adds an unnecessary vendor lock-in and heavy SDK footprint to both client and server.

---

### Decision 2: Mobile Client Google Sign-In Integration (Flutter)
- **Choice**: [`google_sign_in`](https://pub.dev/packages/google_sign_in) Flutter package.
- **Rationale**:
  - Official, mature Google package for Flutter supporting Android, iOS, macOS, and Web.
  - Provides native one-tap bottom sheet on Android (Credential Manager) and Safari WebAuthn on iOS.
  - Directly returns the `GoogleSignInAuthentication.idToken` needed for backend exchange.
- **Alternatives considered**:
  - *Custom WebView / OAuth URL*: Poor UX, triggers security warnings from Google, does not integrate with device system Google accounts.

---

### Decision 3: Web Client Google Sign-In Integration (React 19)
- **Choice**: [`@react-oauth/google`](https://www.npmjs.com/package/@react-oauth/google) or direct Google Identity Services (GIS) Web SDK.
- **Rationale**:
  - Modern GIS (Google Identity Services) iframe/popup standard.
  - Zero server-side redirect URI complexity; yields `credential` (ID token) directly in client callback.
  - Seamlessly integrates with React 19 component lifecycle.

---

### Decision 4: Session Management & Token Format
- **Choice**: Standard HMAC-SHA256 JWT Token with 30-day validity.
- **Rationale**:
  - Google ID tokens expire after 1 hour, making them unsuitable for continuous mobile background sync.
  - The Go backend verifies the Google ID token once, creates/finds the user, and issues a 30-day Simo JWT token.
  - JWT Claims:
    ```json
    {
      "user_id": "9b1deb4d-3b7d-4bad-9bdd-2b0d7b3dcb6d",
      "email": "kiet@example.com",
      "exp": 1790000000,
      "iat": 1787408000
    }
    ```
  - Mobile stores token in `SharedPreferences` / `flutter_secure_storage`; Web stores token in `localStorage`.
- **Alternatives considered**:
  - *Server-side Database Sessions (Redis / Postgres sessions table)*: Adds state lookup on every single API request. JWT is stateless, high-performance, and perfectly matches our layered architecture.

---

### Decision 5: Multi-Tenant PostgreSQL User Upserting
- **Choice**: Upsert on `google_id` with unique constraint in PostgreSQL:
  ```sql
  INSERT INTO users (google_id, email, display_name, avatar_url)
  VALUES ($1, $2, $3, $4)
  ON CONFLICT (google_id) DO UPDATE SET
      email = EXCLUDED.email,
      display_name = EXCLUDED.display_name,
      avatar_url = EXCLUDED.avatar_url,
      updated_at = NOW() AT TIME ZONE 'UTC'
  RETURNING id, email, display_name, avatar_url;
  ```
- **Rationale**:
  - Guarantees consistent `user_id` (UUID) across all sign-ins for the same Google account.
  - Automatically refreshes avatar and display name if the user updates their Google profile.

---

### Decision 6: Local Development & CI/CD Testing Bypass
- **Choice**: Configurable `DEV_AUTH_BYPASS=true` in `apps/server/.env` (or mock exchange `id_token == "mock_google_id_token"`).
- **Rationale**:
  - Allows unit tests, CI test runners, and engineers to run the full stack locally without needing live Google Cloud credentials or internet access.
