package handler

import (
	"net/http"

	"simo-server/internal/middleware"
	"simo-server/internal/repository"
	"simo-server/pkg/response"
)

// WalletHandler handles wallet queries and balance responses for Web.
type WalletHandler struct {
	walletRepo *repository.WalletRepository
}

// NewWalletHandler creates a new WalletHandler.
//
// @param walletRepo *repository.WalletRepository
// @returns *WalletHandler
func NewWalletHandler(walletRepo *repository.WalletRepository) *WalletHandler {
	return &WalletHandler{walletRepo: walletRepo}
}

// ListWallets handles GET /api/v1/wallets.
func (h *WalletHandler) ListWallets(w http.ResponseWriter, r *http.Request) {
	userID, err := middleware.MustGetUserID(r.Context())
	if err != nil {
		response.Error(w, http.StatusUnauthorized, "Unauthorized", "UNAUTHORIZED")
		return
	}

	wallets, err := h.walletRepo.ListWalletsWithBalance(r.Context(), userID)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to query wallets: "+err.Error(), "SERVER_ERROR")
		return
	}

	response.JSON(w, http.StatusOK, "Wallets retrieved successfully", wallets)
}
