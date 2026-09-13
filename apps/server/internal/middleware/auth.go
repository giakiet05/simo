package middleware

import (
	"context"
	"fmt"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"

	"simo-server/pkg/response"
)

type contextKey string

const (
	// UserIDKey is the context key for storing the authenticated user ID.
	UserIDKey contextKey = "user_id"
)

// Claims defines the JWT claims structure for Simo tokens.
type Claims struct {
	UserID string `json:"user_id"`
	Email  string `json:"email"`
	jwt.RegisteredClaims
}

// Auth returns a middleware that validates JWT Bearer tokens and attaches the user ID to context.
//
// @param jwtSecret The secret key used to verify HMAC-signed tokens
// @returns http.Handler middleware
func Auth(jwtSecret string) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			authHeader := r.Header.Get("Authorization")
			var tokenString string

			if authHeader != "" {
				parts := strings.Split(authHeader, " ")
				if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
					response.Error(w, http.StatusUnauthorized, "Invalid Authorization header format. Expected Bearer <token>", "INVALID_TOKEN")
					return
				}
				tokenString = parts[1]
			} else if queryToken := r.URL.Query().Get("token"); queryToken != "" {
				tokenString = queryToken
			} else {
				response.Error(w, http.StatusUnauthorized, "Missing Authorization header or token query parameter", "UNAUTHORIZED")
				return
			}

			// Development bypass: allow dev token
			if tokenString == "dev_token" {
				// Default dev user UUID
				devUserID := "00000000-0000-0000-0000-000000000001"
				ctx := context.WithValue(r.Context(), UserIDKey, devUserID)
				next.ServeHTTP(w, r.WithContext(ctx))
				return
			}

			token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(t *jwt.Token) (interface{}, error) {
				if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, fmt.Errorf("unexpected signing method: %v", t.Header["alg"])
				}
				return []byte(jwtSecret), nil
			})

			if err != nil || !token.Valid {
				response.Error(w, http.StatusUnauthorized, "Invalid or expired token", "INVALID_TOKEN")
				return
			}

			claims, ok := token.Claims.(*Claims)
			if !ok || claims.UserID == "" {
				response.Error(w, http.StatusUnauthorized, "Token claims missing user_id", "INVALID_TOKEN")
				return
			}

			ctx := context.WithValue(r.Context(), UserIDKey, claims.UserID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// GetUserID extracts the authenticated user ID string from context.
//
// @param ctx context.Context
// @returns user_id string and true, or empty string and false if not found
func GetUserID(ctx context.Context) (string, bool) {
	val := ctx.Value(UserIDKey)
	if val == nil {
		return "", false
	}
	userID, ok := val.(string)
	return userID, ok
}

// MustGetUserID extracts user ID as UUID, returning error if missing or invalid.
//
// @param ctx context.Context
// @returns uuid.UUID and error
func MustGetUserID(ctx context.Context) (uuid.UUID, error) {
	str, ok := GetUserID(ctx)
	if !ok || str == "" {
		return uuid.Nil, fmt.Errorf("user not authenticated in context")
	}
	return uuid.Parse(str)
}
