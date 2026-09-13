# Feature Specification: Google Authentication & Cross-Platform Session Management

**Feature Branch**: `017-google-authentication`

**Created**: 2026-09-13

**Status**: Draft

**Input**: User description: "làm auth trước, làm Google luôn đi, tiện khi xài và có thể share cho anh em xài"

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - One-Tap Google Sign-In on Mobile (Priority: P1)

As a Simo mobile user, I want to sign in with my Google account with a single tap, so that my personal financial database is securely tied to my identity and ready to synchronize across all my devices without needing to create or remember a new password.

**Why this priority**: Eliminates authentication friction on mobile devices, secures user data, and serves as the foundation for multi-user cloud synchronization.

**Independent Test**:
1. User opens Simo mobile app on a new or logged-out device.
2. User taps "Đăng nhập với Google" (Sign in with Google).
3. Google account selection prompt appears; user selects their Google account.
4. App authenticates with the backend, displays the user's name and avatar in Settings, and seamlessly transitions into the main dashboard.

**Acceptance Scenarios**:
1. **Given** an unauthenticated user on the mobile app, **When** they tap the Google Sign-In button and authorize their account, **Then** the app receives a Google ID token, exchanges it with the backend for a Simo session token (JWT), stores the session securely, and updates user profile state.
2. **Given** a user who previously tracked finances offline before signing in, **When** they complete Google Sign-In for the first time, **Then** their existing local records (wallets, transactions, categories) are automatically associated with their new user account and queued for cloud sync without data loss.
3. **Given** an authenticated user who closes and reopens the mobile app, **When** the app starts, **Then** their session is automatically restored from secure storage without prompting for re-login.

---

### User Story 2 - Google Sign-In on Web Dashboard (Priority: P1)

As a desktop or laptop user, I want to log in using the standard Google Sign-In button on my web browser, so that I can securely access and manage my financial dashboard from any computer.

**Why this priority**: Enables seamless access to the desktop web management interface, ensuring users can switch between mobile and desktop without friction.

**Independent Test**:
1. User navigates to the Simo Web URL in a desktop browser.
2. An elegant login screen is shown with the "Sign in with Google" button.
3. User completes the Google OAuth flow.
4. Web app receives session credentials, redirects to the Dashboard, and loads their synced financial data.

**Acceptance Scenarios**:
1. **Given** an unauthenticated user visiting the Web app, **When** they complete the Google Sign-In popup or redirect, **Then** the web client sends the Google token to the backend, receives the Simo JWT, stores it in browser local storage, and renders the authenticated dashboard.
2. **Given** an authenticated user on the Web app, **When** they click "Đăng xuất" (Sign Out), **Then** their session token is cleared and the view returns to the login screen immediately.

---

### User Story 3 - Strict Multi-Tenant Data Isolation on Backend (Priority: P1)

As a user sharing a self-hosted or cloud Simo server instance with family or friends, I want complete data privacy and isolation, so that no other authenticated user can read or modify my transactions, wallets, or financial summaries.

**Why this priority**: Core security and privacy guarantee. Prevents cross-tenant data leaks when multiple users share the same server and database instance.

**Independent Test**:
1. User A signs in with `userA@gmail.com` and creates a wallet "Ví Tiền Mặt" with 1,000,000 VND.
2. User B signs in with `userB@gmail.com` on a separate device.
3. User B queries `/wallets`, `/dashboard`, `/transactions`, and `/sync`.
4. User B receives an empty dashboard and 0 wallets; User A's data is completely invisible to User B.

**Acceptance Scenarios**:
1. **Given** an incoming API request to any protected route (`/sync`, `/dashboard`, `/transactions`, `/wallets`), **When** the request is processed, **Then** the backend extracts the user's UUID from the validated JWT claims and scopes all PostgreSQL queries strictly with `WHERE user_id = $authenticated_user_id`.
2. **Given** a request with an invalid, expired, or missing token, **When** reaching the backend, **Then** the request is rejected immediately with HTTP 401 Unauthorized and standard error envelope.

---

### User Story 4 - Seamless Offline Continuity for Authenticated Users (Priority: P2)

As a mobile user in an area without cellular or WiFi coverage, I want the app to open instantly and allow me to record transactions, so that authentication never hinders my ability to log expenses on the go.

**Why this priority**: Upholds Simo's Offline-First core principle. Authentication must never introduce online hard-blocking gates during offline app startup.

**Independent Test**:
1. Authenticated user turns on Airplane Mode (no internet).
2. User opens Simo mobile app.
3. App launches immediately without showing an error or login barrier; user records a new expense.
4. When internet is re-established, the app automatically syncs using the stored session token.

**Acceptance Scenarios**:
1. **Given** an authenticated mobile user without internet connectivity, **When** they launch the app, **Then** the app validates the cached session locally and displays the main screens with full offline read/write capabilities.
2. **Given** a session token that expires while the device is offline, **When** the user next connects to the internet and sync fails with 401, **Then** the app prompts the user to refresh their Google login gracefully while preserving all locally recorded unsynced mutations.

---

### Edge Cases

- **Expired Google ID Token vs. Simo JWT Session**: Google ID tokens have a short lifespan (1 hour), but Simo issues a long-lived JWT session (e.g. 15-30 days) to prevent constant re-login on mobile. Token renewal happens seamlessly.
- **Account Disconnection / Revocation on Google Console**: If a user revokes app permissions from their Google Account settings, the next token exchange or validation fails gracefully with a user-friendly message.
- **Network Timeout during Google OAuth Exchange**: If network drops right after Google returns the ID token but before backend exchange completes, the client allows a retry without losing client-side state.
- **Local Development / Offline Server Deployment**: Backend supports a development bypass mode or configuration flag so engineers can test local instances without registering Google Cloud Console OAuth credentials.

---

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Mobile application MUST integrate Google Sign-In SDK to authenticate users and obtain a cryptographic Google ID Token (`id_token`).
- **FR-002**: Web application MUST integrate Google Identity Services (GIS) button and OAuth popup flow to obtain a Google ID Token.
- **FR-003**: Backend MUST provide a public authentication endpoint `POST /api/v1/auth/google` accepting `{ "id_token": "<google_id_token>" }`.
- **FR-004**: Backend MUST cryptographically verify Google ID Tokens against Google public certificates (JWKS), validating token signature, issuer (`accounts.google.com` or `https://accounts.google.com`), expiration timestamp, and audience (`GOOGLE_CLIENT_ID`).
- **FR-005**: Backend MUST extract Google User ID (`sub`), email, full name, and avatar URL from verified tokens and upsert the record into the `users` table in PostgreSQL.
- **FR-006**: Backend MUST issue a signed HMAC-SHA256 JWT Access Token containing `user_id` (UUID), `email`, and an expiration duration (default: 30 days).
- **FR-007**: Backend API middleware MUST authenticate all protected routes (`/api/v1/sync`, `/api/v1/dashboard`, `/api/v1/transactions`, `/api/v1/wallets`) using the issued JWT and bind the verified `user_id` to request context.
- **FR-008**: Mobile client MUST securely store session tokens in persistent secure storage (`flutter_secure_storage` / encrypted SharedPreferences) and inject them into `Authorization: Bearer <token>` headers for all sync requests.
- **FR-009**: Web client MUST store session tokens in browser `localStorage` and inject them into `Authorization: Bearer <token>` headers for all API requests.
- **FR-010**: System MUST support a Sign-Out function on both Mobile and Web that purges local tokens and resets application authentication state.
- **FR-011**: Mobile client MUST ensure that local financial data created in guest mode is safely migrated to the user's UUID upon initial sign-in.
- **FR-012**: Backend MUST load `GOOGLE_CLIENT_ID` and `JWT_SECRET` strictly from environment variables or `.env` file without hardcoded secrets.

---

### Key Entities

- **User Account**: Represents an authenticated identity in PostgreSQL with `id` (UUID), `email` (unique), `google_id` (unique), `display_name`, `avatar_url`, `created_at`, and `updated_at`.
- **JWT Session Token**: Standard Bearer token payload containing `user_id` (UUID string), `email`, `exp` (expiration timestamp), and `iat` (issued at).
- **Google ID Token**: Cryptographically signed OIDC token issued by Google containing user profile claims (`sub`, `email`, `name`, `picture`, `aud`, `iss`).

---

## Success Criteria *(mandatory)*

- **SC-001**: Users can complete Google Sign-In in under 3 seconds on both Mobile and Web under standard broadband/4G connectivity.
- **SC-002**: 100% of API endpoints reject unauthenticated or tampered requests with HTTP 401 Unauthorized.
- **SC-003**: 100% of database queries for financial entities are strictly scoped to the authenticated user ID, ensuring zero cross-user data leakage.
- **SC-004**: Offline app launch allows 100% full financial tracking functionality without blocking or requiring an active internet connection.
- **SC-005**: User profile avatar and display name sync automatically from Google account to Mobile Settings and Web Navbar upon login.
- **SC-006**: Existing local mobile data created prior to sign-in is preserved and merged into the user's cloud account with 0% data loss.
