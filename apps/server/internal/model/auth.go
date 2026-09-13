package model

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// GoogleAuthRequest represents the payload received from Web or Mobile clients containing the Google ID token.
type GoogleAuthRequest struct {
	IDToken string `json:"id_token"`
}

// UserDTO represents the public sanitized user representation returned in authentication responses.
type UserDTO struct {
	ID          uuid.UUID `json:"id"`
	Email       string    `json:"email"`
	DisplayName *string   `json:"display_name"`
	AvatarURL   *string   `json:"avatar_url"`
}

// AuthResponseData is the payload containing the Simo JWT session token and user profile.
type AuthResponseData struct {
	Token string  `json:"token"`
	User  UserDTO `json:"user"`
}

// UserProfileResponseData represents the full user profile data for /api/v1/auth/me.
type UserProfileResponseData struct {
	ID          uuid.UUID `json:"id"`
	Email       string    `json:"email"`
	DisplayName *string   `json:"display_name"`
	AvatarURL   *string   `json:"avatar_url"`
	CreatedAt   time.Time `json:"created_at"`
}

// JWTCustomClaims represents the claims encoded in the Simo session token.
type JWTCustomClaims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}
