package router

import (
	"net/http"

	"simo-server/internal/config"
	"simo-server/internal/handler"
	"simo-server/internal/middleware"
	"simo-server/pkg/response"
)

// Handlers bundles all API handlers for routing configuration.
type Handlers struct {
	AuthHandler        *handler.AuthHandler
	SyncHandler        *handler.SyncHandler
	SSEHandler         *handler.SSEHandler
	DashboardHandler   *handler.DashboardHandler
	TransactionHandler *handler.TransactionHandler
	WalletHandler      *handler.WalletHandler
}

// SetupRouter initializes the HTTP multiplexer, registers middleware chains, and defines API endpoints.
//
// @param cfg *config.Config
// @param h *Handlers
// @returns http.Handler ready to be served
func SetupRouter(cfg *config.Config, h *Handlers) http.Handler {
	mux := http.NewServeMux()

	// Health check endpoint
	mux.HandleFunc("GET /health", func(w http.ResponseWriter, r *http.Request) {
		response.JSON(w, http.StatusOK, "Simo API Server is running healthy", map[string]string{
			"status": "up",
		})
	})

	// Public Authentication Endpoints
	if h.AuthHandler != nil {
		mux.HandleFunc("POST /api/v1/auth/google", h.AuthHandler.GoogleAuth)
	}

	authMiddleware := middleware.Auth(cfg.JWTSecret)

	// Protected Endpoints
	if h.AuthHandler != nil {
		mux.Handle("GET /api/v1/auth/me", authMiddleware(http.HandlerFunc(h.AuthHandler.GetMe)))
	}
	if h.SyncHandler != nil {
		mux.Handle("POST /api/v1/sync", authMiddleware(http.HandlerFunc(h.SyncHandler.Sync)))
	}
	if h.SSEHandler != nil {
		mux.Handle("GET /api/v1/sync/events", authMiddleware(http.HandlerFunc(h.SSEHandler.Events)))
	}
	if h.DashboardHandler != nil {
		mux.Handle("GET /api/v1/dashboard", authMiddleware(http.HandlerFunc(h.DashboardHandler.GetSummary)))
	}
	if h.TransactionHandler != nil {
		mux.Handle("GET /api/v1/transactions", authMiddleware(http.HandlerFunc(h.TransactionHandler.ListTransactions)))
	}
	if h.WalletHandler != nil {
		mux.Handle("GET /api/v1/wallets", authMiddleware(http.HandlerFunc(h.WalletHandler.ListWallets)))
	}

	// Global Middlewares
	var rootHandler http.Handler = mux
	rootHandler = middleware.CORS(rootHandler)
	rootHandler = middleware.Logger(rootHandler)
	rootHandler = middleware.Recovery(rootHandler)

	return rootHandler
}
