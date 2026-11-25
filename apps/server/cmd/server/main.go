package main

import (
	"context"
	"fmt"
	"log"
	"net/http"
	"os"
	"os/signal"
	"syscall"
	"time"

	"simo-server/internal/config"
	"simo-server/internal/handler"
	"simo-server/internal/repository"
	"simo-server/internal/router"
	"simo-server/internal/service"
	"simo-server/internal/sse"
)

// main bootstraps the Simo backend API server with graceful shutdown handling.
func main() {
	cfg := config.Load()
	if err := cfg.Validate(); err != nil {
		log.Fatalf("Refusing to start with unsafe configuration:\n%v", err)
	}
	if cfg.HasWeakJWTSecret() {
		log.Printf("SECURITY WARNING: JWT_SECRET is short or publicly known; anyone can forge session tokens. Set a private random JWT_SECRET (openssl rand -base64 48) and redeploy.")
	}
	log.Printf("Starting Simo Server on port %s (env=%q)...", cfg.Port, cfg.AppEnv)

	// Cancelled on SIGINT/SIGTERM so that a shutdown during the DB wait exits promptly.
	signalCtx, stopSignals := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stopSignals()

	// In-memory SSE Hub for live multi-device event streaming
	sseHub := sse.NewHub()
	sseHandler := handler.NewSSEHandler(sseHub)

	// The API is useless without the database: previously a failed startup ping left the server
	// running with no API routes registered (every call 404) until someone restarted it by hand.
	// Exit instead, so the container restart policy brings it back once the database is up.
	dbPool, err := repository.InitDBWithRetry(signalCtx, cfg.DatabaseURL, 60*time.Second)
	if err != nil {
		log.Fatalf("Database connection failed on startup: %v", err)
	}
	defer dbPool.Close()
	log.Println("PostgreSQL connection pool initialized successfully.")

	// Ensure incremental schema columns exist idempotently on startup
	if _, err := dbPool.Exec(signalCtx, `ALTER TABLE recurring_configs ADD COLUMN IF NOT EXISTS days_of_week VARCHAR(20)`); err != nil {
		log.Fatalf("Failed to ensure recurring_configs.days_of_week column: %v", err)
	}

	// Auth domain
	userRepo := repository.NewUserRepository(dbPool)
	authService := service.NewAuthService(cfg, userRepo)
	authHandler := handler.NewAuthHandler(authService)

	// Sync domain with SSE broadcast
	syncRepo := repository.NewSyncRepository(dbPool)
	syncService := service.NewSyncService(syncRepo, sseHub)
	syncHandler := handler.NewSyncHandler(syncService)

	// Web Dashboard & CRUD domain
	dashService := service.NewDashboardService(dbPool)
	dashHandler := handler.NewDashboardHandler(dashService)

	txRepo := repository.NewTransactionRepository(dbPool)
	txHandler := handler.NewTransactionHandler(txRepo)

	walletRepo := repository.NewWalletRepository(dbPool)
	walletHandler := handler.NewWalletHandler(walletRepo)

	appRouter := router.SetupRouter(cfg, &router.Handlers{
		AuthHandler:        authHandler,
		SyncHandler:        syncHandler,
		SSEHandler:         sseHandler,
		DashboardHandler:   dashHandler,
		TransactionHandler: txHandler,
		WalletHandler:      walletHandler,
	})

	server := &http.Server{
		Addr:              fmt.Sprintf(":%s", cfg.Port),
		Handler:           appRouter,
		ReadHeaderTimeout: 10 * time.Second,
		IdleTimeout:       60 * time.Second,
	}

	go func() {
		log.Printf("Simo API Server is listening on http://localhost:%s", cfg.Port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("HTTP server error: %v", err)
		}
	}()

	<-signalCtx.Done()
	log.Println("Shutting down Simo API Server gracefully...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server shutdown forced: %v", err)
	}

	log.Println("Server exited cleanly.")
}
