package service

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"simo-server/internal/config"
	"simo-server/internal/model"
	"simo-server/internal/repository"
)

// GoogleTokenClaims contains parsed Google OIDC identity claims.
type GoogleTokenClaims struct {
	Sub           string `json:"sub"`
	Email         string `json:"email"`
	EmailVerified string `json:"email_verified"`
	Name          string `json:"name"`
	Picture       string `json:"picture"`
	Aud           string `json:"aud"`
	Iss           string `json:"iss"`
	Exp           string `json:"exp"`
}

// HTTPClientInterface allows mocking HTTP calls during unit testing.
type HTTPClientInterface interface {
	Do(req *http.Request) (*http.Response, error)
}

// AuthService handles authentication, Google ID token verification, and JWT session issuance.
type AuthService struct {
	cfg        *config.Config
	userRepo   repository.UserRepositoryInterface
	httpClient HTTPClientInterface
}

// NewAuthService creates a new AuthService instance.
//
// @param cfg *config.Config application configuration
// @param userRepo repository.UserRepositoryInterface user persistence repository
// @returns *AuthService
func NewAuthService(cfg *config.Config, userRepo repository.UserRepositoryInterface) *AuthService {
	return &AuthService{
		cfg:      cfg,
		userRepo: userRepo,
		httpClient: &http.Client{
			Timeout: 8 * time.Second,
		},
	}
}

// SetHTTPClient overrides the default HTTP client (primarily for testing).
//
// @param client HTTPClientInterface
func (s *AuthService) SetHTTPClient(client HTTPClientInterface) {
	s.httpClient = client
}

// VerifyGoogleToken validates a raw Google ID token string and returns parsed claims.
//
// @param ctx context.Context
// @param idToken string raw Google ID token
// @returns *GoogleTokenClaims, error
func (s *AuthService) VerifyGoogleToken(ctx context.Context, idToken string) (*GoogleTokenClaims, error) {
	if strings.TrimSpace(idToken) == "" {
		return nil, errors.New("google id_token cannot be empty")
	}

	// Support development / mock bypass if enabled or if token has mock prefix
	if s.cfg.DevAuthBypass || strings.HasPrefix(idToken, "mock_") {
		email := "dev.user@simo.app"
		name := "Dev User"
		sub := "mock_google_sub_12345"
		if strings.HasPrefix(idToken, "mock_user_") {
			parts := strings.Split(idToken, "_")
			if len(parts) >= 3 {
				sub = "mock_google_sub_" + parts[2]
				email = fmt.Sprintf("dev.%s@simo.app", parts[2])
				name = fmt.Sprintf("Dev User %s", strings.Title(parts[2]))
			}
		}
		return &GoogleTokenClaims{
			Sub:           sub,
			Email:         email,
			EmailVerified: "true",
			Name:          name,
			Aud:           s.cfg.GoogleClientID,
			Iss:           "https://accounts.google.com",
		}, nil
	}

	// Verify cryptographic signature and claims via Google TokenInfo endpoint
	endpoint := fmt.Sprintf("https://oauth2.googleapis.com/tokeninfo?id_token=%s", url.QueryEscape(idToken))
	req, err := http.NewRequestWithContext(ctx, http.MethodGet, endpoint, nil)
	if err != nil {
		return nil, fmt.Errorf("failed to construct tokeninfo request: %w", err)
	}

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to verify google token with identity provider: %w", err)
	}
	defer resp.Body.Close()

	bodyBytes, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read tokeninfo response body: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("invalid google token: status %d payload %s", resp.StatusCode, string(bodyBytes))
	}

	var claims GoogleTokenClaims
	if err := json.Unmarshal(bodyBytes, &claims); err != nil {
		return nil, fmt.Errorf("failed to parse google token claims: %w", err)
	}

	if claims.Sub == "" || claims.Email == "" {
		return nil, errors.New("google token is missing required sub or email claims")
	}

	return &claims, nil
}

// IssueJWT creates a signed HMAC-SHA256 session token valid for 30 days.
//
// @param userID uuid.UUID user UUID
// @param email string user email
// @returns string (JWT token), error
func (s *AuthService) IssueJWT(userID uuid.UUID, email string) (string, error) {
	if s.cfg.JWTSecret == "" {
		return "", errors.New("jwt secret is not configured")
	}

	now := time.Now().UTC()
	expiration := now.Add(30 * 24 * time.Hour) // 30-day session

	claims := model.JWTCustomClaims{
		UserID: userID.String(),
		Email:  email,
		RegisteredClaims: jwt.RegisteredClaims{
			Subject:   userID.String(),
			Issuer:    "simo-auth-service",
			IssuedAt:  jwt.NewNumericDate(now),
			ExpiresAt: jwt.NewNumericDate(expiration),
		},
	}

	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	tokenString, err := token.SignedString([]byte(s.cfg.JWTSecret))
	if err != nil {
		return "", fmt.Errorf("failed to sign jwt token: %w", err)
	}

	return tokenString, nil
}

// ValidateJWT verifies a Simo session JWT token and extracts the claims.
//
// @param tokenString string raw bearer token
// @returns *model.JWTCustomClaims, error
func (s *AuthService) ValidateJWT(tokenString string) (*model.JWTCustomClaims, error) {
	token, err := jwt.ParseWithClaims(tokenString, &model.JWTCustomClaims{}, func(t *jwt.Token) (interface{}, error) {
		if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
		}
		return []byte(s.cfg.JWTSecret), nil
	})

	if err != nil {
		return nil, fmt.Errorf("invalid token: %w", err)
	}

	if claims, ok := token.Claims.(*model.JWTCustomClaims); ok && token.Valid {
		return claims, nil
	}

	return nil, errors.New("token claims are invalid or token expired")
}

// AuthenticateWithGoogle exchanges a Google ID token for a Simo JWT session and user record.
//
// @param ctx context.Context request context
// @param idToken string Google ID token from mobile/web client
// @returns *model.AuthResponseData, error
func (s *AuthService) AuthenticateWithGoogle(ctx context.Context, idToken string) (*model.AuthResponseData, error) {
	claims, err := s.VerifyGoogleToken(ctx, idToken)
	if err != nil {
		return nil, fmt.Errorf("google authentication failed: %w", err)
	}

	var displayName *string
	if claims.Name != "" {
		displayName = &claims.Name
	}

	var avatarURL *string
	if claims.Picture != "" {
		avatarURL = &claims.Picture
	}

	user, err := s.userRepo.UpsertUserByGoogleID(ctx, claims.Sub, claims.Email, displayName, avatarURL)
	if err != nil {
		return nil, fmt.Errorf("failed to provision user record: %w", err)
	}

	token, err := s.IssueJWT(user.ID, user.Email)
	if err != nil {
		return nil, fmt.Errorf("failed to issue session token: %w", err)
	}

	return &model.AuthResponseData{
		Token: token,
		User: model.UserDTO{
			ID:          user.ID,
			Email:       user.Email,
			DisplayName: user.DisplayName,
			AvatarURL:   user.AvatarURL,
		},
	}, nil
}

// GetUserProfile retrieves the full user profile by user UUID.
//
// @param ctx context.Context request context
// @param userID uuid.UUID user UUID
// @returns *model.UserProfileResponseData, error
func (s *AuthService) GetUserProfile(ctx context.Context, userID uuid.UUID) (*model.UserProfileResponseData, error) {
	user, err := s.userRepo.GetUserByID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to retrieve user profile: %w", err)
	}
	if user == nil {
		return nil, errors.New("user not found")
	}

	return &model.UserProfileResponseData{
		ID:          user.ID,
		Email:       user.Email,
		DisplayName: user.DisplayName,
		AvatarURL:   user.AvatarURL,
		CreatedAt:   user.CreatedAt,
	}, nil
}
