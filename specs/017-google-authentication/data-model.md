# Data Model & Schema: Google Authentication & User Management

**Feature**: `017-google-authentication` | **Date**: 2026-09-13

---

## 1. Database Entities (PostgreSQL)

### Table: `users`
Represents the authenticated user account and tenant boundary.

```sql
CREATE TABLE IF NOT EXISTS users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    google_id VARCHAR(255) UNIQUE NOT NULL,
    display_name VARCHAR(255),
    avatar_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC'),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() AT TIME ZONE 'UTC')
);

CREATE INDEX IF NOT EXISTS idx_users_google_id ON users(google_id);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);
```

| Column | Type | Constraints | Description |
| :--- | :--- | :--- | :--- |
| `id` | `UUID` | `PRIMARY KEY, DEFAULT gen_random_uuid()` | Internal unique tenant identifier |
| `email` | `VARCHAR(255)` | `UNIQUE, NOT NULL` | Google account email address |
| `google_id` | `VARCHAR(255)` | `UNIQUE, NOT NULL` | Google `sub` (subject identifier) |
| `display_name` | `VARCHAR(255)` | `NULLABLE` | Full name from Google profile |
| `avatar_url` | `TEXT` | `NULLABLE` | Profile picture URI from Google |
| `created_at` | `TIMESTAMPTZ` | `NOT NULL, DEFAULT UTC NOW` | Account creation timestamp |
| `updated_at` | `TIMESTAMPTZ` | `NOT NULL, DEFAULT UTC NOW` | Profile last update timestamp |

---

## 2. API Data Transfer Objects (DTOs)

### 1. `GoogleAuthRequest` (`POST /api/v1/auth/google`)
```typescript
interface GoogleAuthRequest {
  id_token: string; // The cryptographic JWT ID token obtained from Google SDK
}
```

### 2. `AuthResponse`
```typescript
interface AuthResponse {
  token: string; // Simo HMAC-SHA256 JWT session token (valid 30 days)
  user: {
    id: string; // User UUID
    email: string; // User email
    display_name: string; // Profile full name
    avatar_url: string | null; // Profile picture URL
  };
}
```

### 3. `UserProfileResponse` (`GET /api/v1/auth/me`)
```typescript
interface UserProfileResponse {
  id: string;
  email: string;
  display_name: string;
  avatar_url: string | null;
  created_at: string;
}
```

---

## 3. Client State Models

### Mobile Client (`AuthState` in Riverpod)
```dart
enum AuthStatus {
  initial,
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

class AuthState {
  final AuthStatus status;
  final String? token;
  final UserProfile? user;
  final String? errorMessage;

  const AuthState({
    required this.status,
    this.token,
    this.user,
    this.errorMessage,
  });
}
```

### Web Client (`AuthContext` in React)
```typescript
interface AuthContextType {
  user: UserProfile | null;
  token: string | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  loginWithGoogle: (credential: string) => Promise<void>;
  logout: () => void;
}
```
