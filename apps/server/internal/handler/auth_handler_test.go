package handler

import (
	"bytes"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"

	"simo-server/internal/config"
	"simo-server/internal/middleware"
	"simo-server/internal/model"
	"simo-server/internal/service"
)

// MockUserRepository for handler tests
type MockUserRepository struct {
	usersByID     map[uuid.UUID]*model.User
	usersByGoogle map[string]*model.User
}

func NewMockUserRepository() *MockUserRepository {
	return &MockUserRepository{
		usersByID:     make(map[uuid.UUID]*model.User),
		usersByGoogle: make(map[string]*model.User),
	}
}

func (m *MockUserRepository) UpsertUserByGoogleID(ctx context.Context, googleID, email string, displayName, avatarURL *string) (*model.User, error) {
	user, exists := m.usersByGoogle[googleID]
	if !exists {
		user = &model.User{
			ID:          uuid.New(),
			Email:       email,
			GoogleID:    &googleID,
			DisplayName: displayName,
			AvatarURL:   avatarURL,
			CreatedAt:   time.Now().UTC(),
			UpdatedAt:   time.Now().UTC(),
		}
		m.usersByGoogle[googleID] = user
		m.usersByID[user.ID] = user
	}
	return user, nil
}

func (m *MockUserRepository) GetUserByID(ctx context.Context, id uuid.UUID) (*model.User, error) {
	return m.usersByID[id], nil
}

func (m *MockUserRepository) GetUserByGoogleID(ctx context.Context, googleID string) (*model.User, error) {
	return m.usersByGoogle[googleID], nil
}

func TestAuthHandler_GoogleAuth(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:     "secret_123",
		DevAuthBypass: true,
	}
	userRepo := NewMockUserRepository()
	authService := service.NewAuthService(cfg, userRepo)
	authHandler := NewAuthHandler(authService)

	t.Run("Valid Token Exchange", func(t *testing.T) {
		reqBody := model.GoogleAuthRequest{
			IDToken: "mock_google_token_dev",
		}
		bodyBytes, _ := json.Marshal(reqBody)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/google", bytes.NewBuffer(bodyBytes))
		w := httptest.NewRecorder()

		authHandler.GoogleAuth(w, req)

		if w.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d. Body: %s", w.Code, w.Body.String())
		}

		var res struct {
			Message string                 `json:"message"`
			Data    model.AuthResponseData `json:"data"`
		}
		if err := json.Unmarshal(w.Body.Bytes(), &res); err != nil {
			t.Fatalf("failed to decode response: %v", err)
		}

		if res.Data.Token == "" {
			t.Error("expected non-empty token")
		}
		if res.Data.User.Email != "dev.user@simo.app" {
			t.Errorf("expected email dev.user@simo.app, got %s", res.Data.User.Email)
		}
	})

	t.Run("Missing IDToken", func(t *testing.T) {
		reqBody := model.GoogleAuthRequest{
			IDToken: "   ",
		}
		bodyBytes, _ := json.Marshal(reqBody)
		req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/google", bytes.NewBuffer(bodyBytes))
		w := httptest.NewRecorder()

		authHandler.GoogleAuth(w, req)

		if w.Code != http.StatusBadRequest {
			t.Errorf("expected status 400, got %d", w.Code)
		}
	})

	t.Run("Invalid JSON Payload", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodPost, "/api/v1/auth/google", bytes.NewBufferString("{invalid json"))
		w := httptest.NewRecorder()

		authHandler.GoogleAuth(w, req)

		if w.Code != http.StatusBadRequest {
			t.Errorf("expected status 400, got %d", w.Code)
		}
	})
}

func TestAuthHandler_GetMe(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:     "secret_123",
		DevAuthBypass: true,
	}
	userRepo := NewMockUserRepository()
	authService := service.NewAuthService(cfg, userRepo)
	authHandler := NewAuthHandler(authService)

	name := "Alice"
	user, err := userRepo.UpsertUserByGoogleID(context.Background(), "sub_alice", "alice@example.com", &name, nil)
	if err != nil {
		t.Fatalf("failed to seed user: %v", err)
	}

	t.Run("Authenticated Context", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/auth/me", nil)
		ctx := context.WithValue(req.Context(), middleware.UserIDKey, user.ID.String())
		req = req.WithContext(ctx)

		w := httptest.NewRecorder()
		authHandler.GetMe(w, req)

		if w.Code != http.StatusOK {
			t.Fatalf("expected status 200, got %d. Body: %s", w.Code, w.Body.String())
		}

		var res struct {
			Message string                        `json:"message"`
			Data    model.UserProfileResponseData `json:"data"`
		}
		if err := json.Unmarshal(w.Body.Bytes(), &res); err != nil {
			t.Fatalf("failed to unmarshal response: %v", err)
		}

		if res.Data.ID != user.ID || res.Data.Email != "alice@example.com" {
			t.Errorf("unexpected user data: %+v", res.Data)
		}
	})

	t.Run("Unauthenticated Context", func(t *testing.T) {
		req := httptest.NewRequest(http.MethodGet, "/api/v1/auth/me", nil)
		w := httptest.NewRecorder()

		authHandler.GetMe(w, req)

		if w.Code != http.StatusUnauthorized {
			t.Errorf("expected status 401, got %d", w.Code)
		}
	})
}
