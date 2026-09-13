# Quickstart & Verification Guide: Google Authentication

**Feature**: `017-google-authentication` | **Date**: 2026-09-13

---

## 1. Backend Verification via cURL (Mock & Live Exchange)

### Scenario A: Local Development / Mock Token Exchange
When `DEV_AUTH_BYPASS=true` or testing locally without Google Cloud credentials:

```bash
# 1. Exchange Mock Token for Simo Session JWT
curl -X POST http://localhost:8080/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{"id_token": "mock_google_token_dev"}'

# Response Example:
# {
#   "message": "Authenticated successfully",
#   "data": {
#     "token": "eyJhbGciOi...",
#     "user": {
#       "id": "...",
#       "email": "dev.user@simo.app",
#       "display_name": "Dev User",
#       "avatar_url": null
#     }
#   }
# }

# 2. Query /api/v1/auth/me using the received JWT token
curl -X GET http://localhost:8080/api/v1/auth/me \
  -H "Authorization: Bearer <JWT_TOKEN>"
```

### Scenario B: Live Token Verification with Real Google Client ID
```bash
# Set GOOGLE_CLIENT_ID in apps/server/.env
curl -X POST http://localhost:8080/api/v1/auth/google \
  -H "Content-Type: application/json" \
  -d '{"id_token": "<ACTUAL_GOOGLE_ID_TOKEN>"}'
```

---

## 2. Web Client Verification (Browser Flow)

1. Open [http://localhost:3000](http://localhost:3000).
2. If unauthenticated, the login page displays the official "Sign in with Google" button.
3. Click "Sign in with Google" and complete authorization in the popup.
4. Verify that:
   - The user is redirected to the Dashboard.
   - The top Navbar displays the user's Google avatar and display name.
   - An "Account / Sign Out" button is present.
   - Refreshing the page (F5) preserves the logged-in session.

---

## 3. Mobile Client Verification (Flutter)

1. Launch Flutter app:
   ```bash
   cd apps/mobile && flutter run
   ```
2. Navigate to **Cài đặt (Settings)** $\rightarrow$ **Đăng nhập với Google**.
3. Complete the Google account picker.
4. Verify that:
   - The user's name and avatar appear in the profile card.
   - Local unsynced transactions are automatically tagged and pushed to the cloud.
   - Turning on Airplane Mode and restarting the app maintains full offline access.
