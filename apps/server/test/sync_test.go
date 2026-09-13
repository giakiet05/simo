package test

import (
	"bytes"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/google/uuid"

	"simo-server/internal/config"
	"simo-server/internal/handler"
	"simo-server/internal/model"
	"simo-server/internal/repository"
	"simo-server/internal/router"
	"simo-server/internal/service"
)

// TestSyncCycle_Integration verifies full-duplex sync with Push and Pull between two simulated devices.
func TestSyncCycle_Integration(t *testing.T) {
	cfg := config.Load()
	if cfg.DatabaseURL == "" {
		t.Skip("Skipping integration test: DATABASE_URL not configured")
	}

	pool, err := repository.InitDB(cfg.DatabaseURL)
	if err != nil {
		t.Skipf("Skipping integration test: database connection failed: %v", err)
	}
	defer pool.Close()

	syncRepo := repository.NewSyncRepository(pool)
	syncService := service.NewSyncService(syncRepo, nil)
	syncHandler := handler.NewSyncHandler(syncService)

	appRouter := router.SetupRouter(cfg, &router.Handlers{
		SyncHandler: syncHandler,
	})

	walletID := uuid.New()
	txID := uuid.New()
	now := time.Now().UTC()

	// 1. Device A pushes new wallet and transaction
	pushReqA := model.SyncRequest{
		DeviceID: "device_a",
		Mutations: model.SyncMutations{
			Wallets: []model.WalletSync{
				{
					ID:              walletID,
					Name:            "Cash Wallet",
					Type:            "cash",
					InitialBalance:  1000000,
					Color:           "#10B981",
					Icon:            "wallet",
					IsDefault:       true,
					ClientCreatedAt: model.NewFlexibleTime(now),
					ClientUpdatedAt: model.NewFlexibleTime(now),
				},
			},
			Transactions: []model.TransactionSync{
				{
					ID:              txID,
					WalletID:        &walletID,
					Amount:          50000,
					Type:            "expense",
					TransactionDate: "2026-09-12",
					Note:            ptr("Lunch expense"),
					ClientCreatedAt: model.NewFlexibleTime(now),
					ClientUpdatedAt: model.NewFlexibleTime(now),
				},
			},
		},
	}

	bodyA, _ := json.Marshal(pushReqA)
	reqA := httptest.NewRequest(http.MethodPost, "/api/v1/sync", bytes.NewReader(bodyA))
	reqA.Header.Set("Content-Type", "application/json")
	reqA.Header.Set("Authorization", "Bearer dev_token")
	// Set test context user ID
	wA := httptest.NewRecorder()

	appRouter.ServeHTTP(wA, reqA)

	if wA.Code != http.StatusOK {
		t.Fatalf("Device A sync failed with status %d: %s", wA.Code, wA.Body.String())
	}

	// 2. Device B pulls changes
	pullReqB := model.SyncRequest{
		DeviceID:             "device_b",
		LastSyncedServerTime: nil, // Pull all
		Mutations:            model.SyncMutations{},
	}
	bodyB, _ := json.Marshal(pullReqB)
	reqB := httptest.NewRequest(http.MethodPost, "/api/v1/sync", bytes.NewReader(bodyB))
	reqB.Header.Set("Content-Type", "application/json")
	reqB.Header.Set("Authorization", "Bearer dev_token")
	wB := httptest.NewRecorder()

	appRouter.ServeHTTP(wB, reqB)

	if wB.Code != http.StatusOK {
		t.Fatalf("Device B sync failed with status %d: %s", wB.Code, wB.Body.String())
	}

	var resB struct {
		Data model.SyncResponseData `json:"data"`
	}
	if err := json.Unmarshal(wB.Body.Bytes(), &resB); err != nil {
		t.Fatalf("Failed to parse Device B response: %v", err)
	}

	if len(resB.Data.Changes.Wallets) == 0 {
		t.Error("Expected Device B to receive pushed wallet from Device A, got 0")
	}
	if len(resB.Data.Changes.Transactions) == 0 {
		t.Error("Expected Device B to receive pushed transaction from Device A, got 0")
	}
}

func ptr(s string) *string {
	return &s
}
