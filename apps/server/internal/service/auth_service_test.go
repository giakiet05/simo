package service

import (
	"bytes"
	"context"
	"errors"
	"io"
	"net/http"
	"testing"
	"time"

	"github.com/google/uuid"

	"simo-server/internal/config"
	"simo-server/internal/model"
)

// MockUserRepository implements repository.UserRepositoryInterface for tests.
type MockUserRepository struct {
	usersByID     map[uuid.UUID]*model.User
	usersByGoogle map[string]*model.User
	upsertErr     error
	getErr        error
}

func NewMockUserRepository() *MockUserRepository {
	return &MockUserRepository{
		usersByID:     make(map[uuid.UUID]*model.User),
		usersByGoogle: make(map[string]*model.User),
	}
}

func (m *MockUserRepository) UpsertUserByGoogleID(ctx context.Context, googleID, email string, displayName, avatarURL *string) (*model.User, error) {
	if m.upsertErr != nil {
		return nil, m.upsertErr
	}
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
	} else {
		user.Email = email
		user.DisplayName = displayName
		user.AvatarURL = avatarURL
		user.UpdatedAt = time.Now().UTC()
	}
	return user, nil
}

func (m *MockUserRepository) GetUserByID(ctx context.Context, id uuid.UUID) (*model.User, error) {
	if m.getErr != nil {
		return nil, m.getErr
	}
	return m.usersByID[id], nil
}

func (m *MockUserRepository) GetUserByGoogleID(ctx context.Context, googleID string) (*model.User, error) {
	if m.getErr != nil {
		return nil, m.getErr
	}
	return m.usersByGoogle[googleID], nil
}

// MockHTTPClient intercepts HTTP calls for Google TokenInfo testing.
type MockHTTPClient struct {
	statusCode int
	body       string
	err        error
}

func (m *MockHTTPClient) Do(req *http.Request) (*http.Response, error) {
	if m.err != nil {
		return nil, m.err
	}
	return &http.Response{
		StatusCode: m.statusCode,
		Body:       io.NopCloser(bytes.NewBufferString(m.body)),
		Header:     make(http.Header),
	}, nil
}

func TestVerifyGoogleToken_DevBypass(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:     "test_secret",
		DevAuthBypass: true,
	}
	repo := NewMockUserRepository()
	authService := NewAuthService(cfg, repo)

	claims, err := authService.VerifyGoogleToken(context.Background(), "mock_google_token_dev")
	if err != nil {
		t.Fatalf("expected nil error in dev bypass mode, got: %v", err)
	}

	if claims.Email != "dev.user@simo.app" {
		t.Errorf("expected email dev.user@simo.app, got: %s", claims.Email)
	}
	if claims.Sub != "mock_google_sub_12345" {
		t.Errorf("expected sub mock_google_sub_12345, got: %s", claims.Sub)
	}
}

func TestVerifyGoogleToken_LiveHTTP(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:      "test_secret",
		DevAuthBypass:  false,
		GoogleClientID: "test-client-id",
	}
	repo := NewMockUserRepository()
	authService := NewAuthService(cfg, repo)

	// Test Successful TokenInfo Response
	authService.SetHTTPClient(&MockHTTPClient{
		statusCode: http.StatusOK,
		body: `{
			"sub": "10987654321",
			"email": "kiet@example.com",
			"email_verified": "true",
			"name": "Kiet Gia",
			"picture": "https://lh3.googleusercontent.com/a/photo.jpg",
			"aud": "test-client-id",
			"iss": "https://accounts.google.com"
		}`,
	})

	claims, err := authService.VerifyGoogleToken(context.Background(), "valid_google_token")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if claims.Email != "kiet@example.com" || claims.Name != "Kiet Gia" {
		t.Errorf("claims mismatch: %+v", claims)
	}

	// Test Invalid Token (400 Bad Request)
	authService.SetHTTPClient(&MockHTTPClient{
		statusCode: http.StatusBadRequest,
		body:       `{"error_description": "Invalid Value"}`,
	})

	_, err = authService.VerifyGoogleToken(context.Background(), "invalid_token")
	if err == nil {
		t.Fatal("expected error for invalid token, got nil")
	}
}

func TestJWTIssuanceAndValidation(t *testing.T) {
	cfg := &config.Config{
		JWTSecret: "super_secret_test_key_12345",
	}
	repo := NewMockUserRepository()
	authService := NewAuthService(cfg, repo)

	userID := uuid.New()
	email := "test@simo.app"

	tokenString, err := authService.IssueJWT(userID, email)
	if err != nil {
		t.Fatalf("failed to issue jwt: %v", err)
	}
	if tokenString == "" {
		t.Fatal("expected non-empty token string")
	}

	claims, err := authService.ValidateJWT(tokenString)
	if err != nil {
		t.Fatalf("failed to validate jwt: %v", err)
	}

	if claims.UserID != userID.String() {
		t.Errorf("expected user_id %s, got %s", userID.String(), claims.UserID)
	}
	if claims.Email != email {
		t.Errorf("expected email %s, got %s", email, claims.Email)
	}

	// Test Tampered Token
	tamperedToken := tokenString + "tampered"
	_, err = authService.ValidateJWT(tamperedToken)
	if err == nil {
		t.Fatal("expected error for tampered token, got nil")
	}
}

func TestAuthenticateWithGoogle_FullFlow(t *testing.T) {
	cfg := &config.Config{
		JWTSecret:     "secret_12345",
		DevAuthBypass: true,
	}
	repo := NewMockUserRepository()
	authService := NewAuthService(cfg, repo)

	res, err := authService.AuthenticateWithGoogle(context.Background(), "mock_user_alice_token")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if res.Token == "" {
		t.Error("expected non-empty session token")
	}
	if res.User.Email != "dev.alice@simo.app" {
		t.Errorf("expected email dev.alice@simo.app, got %s", res.User.Email)
	}

	// Validate issued token with service
	claims, err := authService.ValidateJWT(res.Token)
	if err != nil {
		t.Fatalf("issued token validation failed: %v", err)
	}
	if claims.UserID != res.User.ID.String() {
		t.Errorf("claims user_id mismatch: %s vs %s", claims.UserID, res.User.ID.String())
	}
}

func TestGetUserProfile(t *testing.T) {
	cfg := &config.Config{JWTSecret: "secret_12345"}
	repo := NewMockUserRepository()
	authService := NewAuthService(cfg, repo)

	name := "Alice"
	user, err := repo.UpsertUserByGoogleID(context.Background(), "sub_alice", "alice@example.com", &name, nil)
	if err != nil {
		t.Fatalf("failed to seed user: %v", err)
	}

	profile, err := authService.GetUserProfile(context.Background(), user.ID)
	if err != nil {
		t.Fatalf("failed to get user profile: %v", err)
	}
	if profile.Email != "alice@example.com" || profile.DisplayName == nil || *profile.DisplayName != "Alice" {
		t.Errorf("unexpected profile data: %+v", profile)
	}

	// Non-existent user
	_, err = authService.GetUserProfile(context.Background(), uuid.New())
	if !errors.Is(err, errors.New("user not found")) && err.Error() != "user not found" {
		t.Errorf("expected user not found error, got: %v", err)
	}
}
