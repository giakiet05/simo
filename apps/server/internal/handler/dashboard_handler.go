package handler

import (
	"net/http"
	"strconv"
	"time"

	"simo-server/internal/middleware"
	"simo-server/internal/service"
	"simo-server/pkg/response"
)

// DashboardHandler handles dashboard KPI queries.
type DashboardHandler struct {
	dashService *service.DashboardService
}

// NewDashboardHandler creates a new DashboardHandler.
//
// @param dashService *service.DashboardService
// @returns *DashboardHandler
func NewDashboardHandler(dashService *service.DashboardService) *DashboardHandler {
	return &DashboardHandler{dashService: dashService}
}

// GetSummary handles GET /api/v1/dashboard.
func (h *DashboardHandler) GetSummary(w http.ResponseWriter, r *http.Request) {
	userID, err := middleware.MustGetUserID(r.Context())
	if err != nil {
		response.Error(w, http.StatusUnauthorized, "Unauthorized", "UNAUTHORIZED")
		return
	}

	now := time.Now()
	year, _ := strconv.Atoi(r.URL.Query().Get("year"))
	month, _ := strconv.Atoi(r.URL.Query().Get("month"))

	if year <= 0 {
		year = now.Year()
	}
	if month <= 0 {
		month = int(now.Month())
	}

	summary, err := h.dashService.GetSummary(r.Context(), userID, year, month)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to compute dashboard: "+err.Error(), "SERVER_ERROR")
		return
	}

	response.JSON(w, http.StatusOK, "Dashboard summary retrieved successfully", summary)
}
