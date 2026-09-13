package handler

import (
	"encoding/json"
	"net/http"
	"strings"

	"simo-server/internal/middleware"
	"simo-server/internal/model"
	"simo-server/internal/service"
	"simo-server/pkg/response"
)

// AuthHandler handles authentication and session profile endpoints.
type AuthHandler struct {
	authService *service.AuthService
}

// NewAuthHandler creates a new AuthHandler instance.
//
// @param authService *service.AuthService
// @returns *AuthHandler
func NewAuthHandler(authService *service.AuthService) *AuthHandler {
	return &AuthHandler{authService: authService}
}

// GoogleAuth handles POST /api/v1/auth/google
// Exchanges a Google ID Token for a Simo JWT session and user record.
//
// @param w http.ResponseWriter
// @param r *http.Request
func (h *AuthHandler) GoogleAuth(w http.ResponseWriter, r *http.Request) {
	var req model.GoogleAuthRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.Error(w, http.StatusBadRequest, "Invalid request JSON payload: "+err.Error(), "INVALID_REQUEST")
		return
	}

	if strings.TrimSpace(req.IDToken) == "" {
		response.Error(w, http.StatusBadRequest, "id_token field is required", "MISSING_ID_TOKEN")
		return
	}

	authRes, err := h.authService.AuthenticateWithGoogle(r.Context(), req.IDToken)
	if err != nil {
		response.Error(w, http.StatusUnauthorized, "Authentication failed: "+err.Error(), "AUTH_FAILED")
		return
	}

	response.JSON(w, http.StatusOK, "Authenticated successfully", authRes)
}

// GetMe handles GET /api/v1/auth/me
// Returns the profile of the currently authenticated user.
//
// @param w http.ResponseWriter
// @param r *http.Request
func (h *AuthHandler) GetMe(w http.ResponseWriter, r *http.Request) {
	userID, err := middleware.MustGetUserID(r.Context())
	if err != nil {
		response.Error(w, http.StatusUnauthorized, "User is not authenticated", "UNAUTHORIZED")
		return
	}

	profile, err := h.authService.GetUserProfile(r.Context(), userID)
	if err != nil {
		response.Error(w, http.StatusNotFound, "User profile not found: "+err.Error(), "USER_NOT_FOUND")
		return
	}

	response.JSON(w, http.StatusOK, "User profile retrieved successfully", profile)
}
