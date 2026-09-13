package handler

import (
	"encoding/json"
	"net/http"

	"simo-server/internal/middleware"
	"simo-server/internal/model"
	"simo-server/internal/service"
	"simo-server/pkg/response"
)

// SyncHandler handles HTTP requests for the synchronization endpoint.
type SyncHandler struct {
	syncService *service.SyncService
}

// NewSyncHandler creates a new SyncHandler instance.
//
// @param syncService *service.SyncService
// @returns *SyncHandler
func NewSyncHandler(syncService *service.SyncService) *SyncHandler {
	return &SyncHandler{syncService: syncService}
}

// Sync handles POST /api/v1/sync requests.
//
// @param w http.ResponseWriter
// @param r *http.Request
func (h *SyncHandler) Sync(w http.ResponseWriter, r *http.Request) {
	userID, err := middleware.MustGetUserID(r.Context())
	if err != nil {
		response.Error(w, http.StatusUnauthorized, "User is not authenticated", "UNAUTHORIZED")
		return
	}

	var req model.SyncRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		response.Error(w, http.StatusBadRequest, "Invalid request JSON payload: "+err.Error(), "INVALID_REQUEST")
		return
	}

	res, err := h.syncService.Sync(r.Context(), userID, &req)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Sync processing error: "+err.Error(), "SYNC_ERROR")
		return
	}

	response.JSON(w, http.StatusOK, "Sync completed successfully", res)
}
