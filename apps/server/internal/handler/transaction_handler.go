package handler

import (
	"net/http"
	"strconv"

	"github.com/google/uuid"

	"simo-server/internal/middleware"
	"simo-server/internal/repository"
	"simo-server/pkg/response"
)

// TransactionHandler handles REST endpoints for transactions on Web.
type TransactionHandler struct {
	txRepo *repository.TransactionRepository
}

// NewTransactionHandler creates a new TransactionHandler.
//
// @param txRepo *repository.TransactionRepository
// @returns *TransactionHandler
func NewTransactionHandler(txRepo *repository.TransactionRepository) *TransactionHandler {
	return &TransactionHandler{txRepo: txRepo}
}

// ListTransactions handles GET /api/v1/transactions.
func (h *TransactionHandler) ListTransactions(w http.ResponseWriter, r *http.Request) {
	userID, err := middleware.MustGetUserID(r.Context())
	if err != nil {
		response.Error(w, http.StatusUnauthorized, "Unauthorized", "UNAUTHORIZED")
		return
	}

	page, _ := strconv.Atoi(r.URL.Query().Get("page"))
	limit, _ := strconv.Atoi(r.URL.Query().Get("limit"))
	typeParam := r.URL.Query().Get("type")
	catParam := r.URL.Query().Get("category_id")
	startDate := r.URL.Query().Get("start_date")
	endDate := r.URL.Query().Get("end_date")
	keyword := r.URL.Query().Get("keyword")

	var walletUUID *uuid.UUID
	if wStr := r.URL.Query().Get("wallet_id"); wStr != "" {
		if id, err := uuid.Parse(wStr); err == nil {
			walletUUID = &id
		}
	}

	filter := repository.TransactionFilter{
		Page:       page,
		Limit:      limit,
		WalletID:   walletUUID,
		Type:       &typeParam,
		CategoryID: &catParam,
		StartDate:  &startDate,
		EndDate:    &endDate,
		Keyword:    &keyword,
	}

	items, total, err := h.txRepo.ListTransactions(r.Context(), userID, filter)
	if err != nil {
		response.Error(w, http.StatusInternalServerError, "Failed to query transactions: "+err.Error(), "SERVER_ERROR")
		return
	}

	response.JSON(w, http.StatusOK, "Transactions retrieved successfully", map[string]any{
		"items": items,
		"total": total,
		"page":  page,
		"limit": limit,
	})
}
