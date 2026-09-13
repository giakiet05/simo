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
	log.Printf("Starting Simo Server on port %s...", cfg.Port)

	// In-memory SSE Hub for live multi-device event streaming
	sseHub := sse.NewHub()
	sseHandler := handler.NewSSEHandler(sseHub)

	// Initialize Database Pool
	var authHandler *handler.AuthHandler
	var syncHandler *handler.SyncHandler
	var dashHandler *handler.DashboardHandler
	var txHandler *handler.TransactionHandler
	var walletHandler *handler.WalletHandler

	dbPool, err := repository.InitDB(cfg.DatabaseURL)
	if err != nil {
		log.Printf("Warning: Database connection failed on startup: %v. Running in offline/disconnected mode.", err)
	} else {
		defer dbPool.Close()
		log.Println("PostgreSQL connection pool initialized successfully.")

		// Auth domain
		userRepo := repository.NewUserRepository(dbPool)
		authService := service.NewAuthService(cfg, userRepo)
		authHandler = handler.NewAuthHandler(authService)

		// Sync domain with SSE broadcast
		syncRepo := repository.NewSyncRepository(dbPool)
		syncService := service.NewSyncService(syncRepo, sseHub)
		syncHandler = handler.NewSyncHandler(syncService)

		// Web Dashboard & CRUD domain
		dashService := service.NewDashboardService(dbPool)
		dashHandler = handler.NewDashboardHandler(dashService)

		txRepo := repository.NewTransactionRepository(dbPool)
		txHandler = handler.NewTransactionHandler(txRepo)

		walletRepo := repository.NewWalletRepository(dbPool)
		walletHandler = handler.NewWalletHandler(walletRepo)
	}

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

	shutdownChan := make(chan os.Signal, 1)
	signal.Notify(shutdownChan, os.Interrupt, syscall.SIGTERM)

	go func() {
		log.Printf("Simo API Server is listening on http://localhost:%s", cfg.Port)
		if err := server.ListenAndServe(); err != nil && err != http.ErrServerClosed {
			log.Fatalf("HTTP server error: %v", err)
		}
	}()

	<-shutdownChan
	log.Println("Shutting down Simo API Server gracefully...")

	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	if err := server.Shutdown(ctx); err != nil {
		log.Fatalf("Server shutdown forced: %v", err)
	}

	log.Println("Server exited cleanly.")
}
