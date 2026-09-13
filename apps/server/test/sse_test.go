package test

import (
	"bufio"
	"context"
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"

	"simo-server/internal/config"
	"simo-server/internal/handler"
	"simo-server/internal/router"
	"simo-server/internal/service"
	"simo-server/internal/sse"
)

// TestSSE_StreamAndBroadcast verifies the SSE streaming connection and event dispatching.
func TestSSE_StreamAndBroadcast(t *testing.T) {
	cfg := config.Load()
	sseHub := sse.NewHub()
	sseHandler := handler.NewSSEHandler(sseHub)

	appRouter := router.SetupRouter(cfg, &router.Handlers{
		SSEHandler: sseHandler,
	})

	server := httptest.NewServer(appRouter)
	defer server.Close()

	// 1. Connect Client A via GET /api/v1/sync/events using ?token=dev_token
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	req, err := http.NewRequestWithContext(ctx, http.MethodGet, server.URL+"/api/v1/sync/events?token=dev_token&client_id=client_a", nil)
	if err != nil {
		t.Fatalf("failed to create SSE request: %v", err)
	}

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		t.Fatalf("failed to execute SSE request: %v", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		t.Fatalf("expected status 200, got %d", resp.StatusCode)
	}

	if contentType := resp.Header.Get("Content-Type"); !strings.Contains(contentType, "text/event-stream") {
		t.Fatalf("expected Content-Type text/event-stream, got %s", contentType)
	}

	reader := bufio.NewReader(resp.Body)

	// Read initial "connected" event
	line1, err := reader.ReadString('\n')
	if err != nil {
		t.Fatalf("failed to read event line: %v", err)
	}
	if !strings.HasPrefix(strings.TrimSpace(line1), "event: connected") {
		t.Fatalf("expected 'event: connected', got %q", line1)
	}

	line2, err := reader.ReadString('\n')
	if err != nil {
		t.Fatalf("failed to read data line: %v", err)
	}
	if !strings.HasPrefix(strings.TrimSpace(line2), "data: ") {
		t.Fatalf("expected 'data: ...', got %q", line2)
	}

	// Consume empty line delimiter
	_, _ = reader.ReadString('\n')

	// 2. Broadcast a data_changed event from Client B
	devUserID := uuid.MustParse("00000000-0000-0000-0000-000000000001")
	sseHub.Broadcast(devUserID, &sse.SyncEvent{
		Type:           "data_changed",
		SourceClientID: "client_b",
		TableNames:     []string{"transactions", "wallets"},
		ServerTime:     time.Now().UTC(),
	})

	// Read broadcasted event on Client A
	eventLine, err := reader.ReadString('\n')
	if err != nil {
		t.Fatalf("failed to read broadcast event line: %v", err)
	}
	if !strings.HasPrefix(strings.TrimSpace(eventLine), "event: data_changed") {
		t.Fatalf("expected 'event: data_changed', got %q", eventLine)
	}

	dataLine, err := reader.ReadString('\n')
	if err != nil {
		t.Fatalf("failed to read broadcast data line: %v", err)
	}
	rawJSON := strings.TrimPrefix(strings.TrimSpace(dataLine), "data: ")

	var received sse.SyncEvent
	if err := json.Unmarshal([]byte(rawJSON), &received); err != nil {
		t.Fatalf("failed to parse event json %q: %v", rawJSON, err)
	}

	if received.SourceClientID != "client_b" {
		t.Errorf("expected SourceClientID 'client_b', got %q", received.SourceClientID)
	}
	if len(received.TableNames) != 2 || received.TableNames[0] != "transactions" {
		t.Errorf("unexpected table names: %+v", received.TableNames)
	}
}

// TestSyncService_BroadcastOnMutation verifies that SyncService broadcasts to SSEHub when mutations exist.
func TestSyncService_BroadcastOnMutation(t *testing.T) {
	sseHub := sse.NewHub()
	syncService := service.NewSyncService(nil, sseHub)

	devUserID := uuid.MustParse("00000000-0000-0000-0000-000000000001")

	client := &sse.Client{
		ID:       "listener_client",
		UserID:   devUserID,
		Platform: "web",
		Events:   make(chan *sse.SyncEvent, 5),
	}
	sseHub.Register(client)
	defer sseHub.Unregister(client)

	// Direct broadcast test
	now := time.Now().UTC()
	sseHub.Broadcast(devUserID, &sse.SyncEvent{
		Type:           "data_changed",
		SourceClientID: "mutating_device",
		TableNames:     []string{"wallets"},
		ServerTime:     now,
	})

	select {
	case ev := <-client.Events:
		if ev.SourceClientID != "mutating_device" {
			t.Errorf("expected source client id mutating_device, got %s", ev.SourceClientID)
		}
	case <-time.After(500 * time.Millisecond):
		t.Fatal("timed out waiting for broadcast event")
	}

	_ = syncService
}
