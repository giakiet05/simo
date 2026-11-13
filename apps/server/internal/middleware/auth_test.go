package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
)

// serveWithToken runs a request bearing the given token through the Auth middleware.
// It returns the response status code and the user ID the protected handler observed.
func serveWithToken(t *testing.T, devBypass bool, token string) (int, string) {
	t.Helper()
	var seenUserID string
	protected := Auth("test_secret", devBypass)(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		seenUserID, _ = GetUserID(r.Context())
		w.WriteHeader(http.StatusOK)
	}))
	req := httptest.NewRequest(http.MethodGet, "/api/v1/wallets", nil)
	req.Header.Set("Authorization", "Bearer "+token)
	rec := httptest.NewRecorder()
	protected.ServeHTTP(rec, req)
	return rec.Code, seenUserID
}

func TestAuth_DevTokenRejectedWithoutBypass(t *testing.T) {
	code, userID := serveWithToken(t, false, "dev_token")
	if code != http.StatusUnauthorized {
		t.Fatalf("expected 401 for dev_token without bypass, got %d", code)
	}
	if userID != "" {
		t.Fatalf("protected handler must not run, but saw user %q", userID)
	}
}

func TestAuth_DevTokenAcceptedWithBypass(t *testing.T) {
	code, userID := serveWithToken(t, true, "dev_token")
	if code != http.StatusOK {
		t.Fatalf("expected 200 for dev_token with bypass, got %d", code)
	}
	if userID != "00000000-0000-0000-0000-000000000001" {
		t.Fatalf("unexpected dev user id %q", userID)
	}
}

func TestAuth_GarbageTokenRejected(t *testing.T) {
	code, _ := serveWithToken(t, true, "not-a-jwt")
	if code != http.StatusUnauthorized {
		t.Fatalf("expected 401 for invalid token, got %d", code)
	}
}
