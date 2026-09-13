package service

import (
	"net/http"
	"net/http/httptest"
	"testing"

	"github.com/google/uuid"

	"simo-server/internal/config"
	"simo-server/internal/middleware"
)

func TestMultiTenantJWT_IsolationAndRejection(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:     "multi_tenant_test_secret_key_9999",
		DevAuthBypass: false,
	}
	repo := NewMockUserRepository()
	authService := NewAuthService(cfg, repo)

	userAID := uuid.New()
	userBID := uuid.New()

	tokenA, err := authService.IssueJWT(userAID, "userA@simo.app")
	if err != nil {
		t.Fatalf("failed to issue token for User A: %v", err)
	}

	tokenB, err := authService.IssueJWT(userBID, "userB@simo.app")
	if err != nil {
		t.Fatalf("failed to issue token for User B: %v", err)
	}

	authMiddleware := middleware.Auth(cfg.JWTSecret)

	// Handler that extracts user_id and verifies tenant
	var capturedUserID uuid.UUID
	dummyProtectedHandler := http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		uid, err := middleware.MustGetUserID(r.Context())
		if err != nil {
			http.Error(w, "unauthorized", http.StatusUnauthorized)
			return
		}
		capturedUserID = uid
		w.WriteHeader(http.StatusOK)
		w.Write([]byte(`{"status":"ok"}`))
	})

	protectedChain := authMiddleware(dummyProtectedHandler)

	t.Run("Reject Request Without Authorization Header", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/dashboard", nil)
		w := httptest.NewRecorder()

		protectedChain.ServeHTTP(w, req)

		if w.Code != http.StatusUnauthorized {
			t.Errorf("expected status 401, got %d", w.Code)
		}
	})

	t.Run("Reject Tampered Token", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/dashboard", nil)
		req.Header.Set("Authorization", "Bearer "+tokenA+"tampered")
		w := httptest.NewRecorder()

		protectedChain.ServeHTTP(w, req)

		if w.Code != http.StatusUnauthorized {
			t.Errorf("expected status 401 for tampered token, got %d", w.Code)
		}
	})

	t.Run("Accept User A Token and Extract User A UUID", func(t *testing.T) {
		capturedUserID = uuid.Nil
		req := httptest.NewRequest(http.MethodGet, "/api/v1/dashboard", nil)
		req.Header.Set("Authorization", "Bearer "+tokenA)
		w := httptest.NewRecorder()

		protectedChain.ServeHTTP(w, req)

		if w.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d", w.Code)
		}
		if capturedUserID != userAID {
			t.Errorf("expected user ID %s for User A, got %s", userAID, capturedUserID)
		}
	})

	t.Run("Accept User B Token and Extract User B UUID (Strict Isolation)", func(t *testing.T) {
		capturedUserID = uuid.Nil
		req := httptest.NewRequest(http.MethodGet, "/api/v1/dashboard", nil)
		req.Header.Set("Authorization", "Bearer "+tokenB)
		w := httptest.NewRecorder()

		protectedChain.ServeHTTP(w, req)

		if w.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d", w.Code)
		}
		if capturedUserID != userBID {
			t.Errorf("expected user ID %s for User B, got %s", userBID, capturedUserID)
		}
		if capturedUserID == userAID {
			t.Errorf("User B request mistakenly received User A identity!")
		}
	})
}
