package sse

import (
	"sync"
	"testing"
	"time"

	"github.com/google/uuid"
)

func TestHub_RegisterAndBroadcast(t *testing.T) {
	hub := NewHub()
	userID := uuid.New()

	client1 := &Client{
		ID:       "client-1",
		UserID:   userID,
		Platform: "web",
		Events:   make(chan *SyncEvent, 10),
	}

	client2 := &Client{
		ID:       "client-2",
		UserID:   userID,
		Platform: "mobile",
		Events:   make(chan *SyncEvent, 10),
	}

	hub.Register(client1)
	hub.Register(client2)

	if count := hub.ConnectedClientsCount(userID); count != 2 {
		t.Fatalf("expected 2 connected clients, got %d", count)
	}

	event := &SyncEvent{
		Type:           "data_changed",
		SourceClientID: "client-1",
		TableNames:     []string{"transactions"},
		ServerTime:     time.Now().UTC(),
	}

	hub.Broadcast(userID, event)

	select {
	case received := <-client1.Events:
		if received.Type != "data_changed" || received.SourceClientID != "client-1" {
			t.Errorf("client1 received unexpected event: %+v", received)
		}
	case <-time.After(500 * time.Millisecond):
		t.Fatal("client1 timed out waiting for event")
	}

	select {
	case received := <-client2.Events:
		if received.Type != "data_changed" || received.SourceClientID != "client-1" {
			t.Errorf("client2 received unexpected event: %+v", received)
		}
	case <-time.After(500 * time.Millisecond):
		t.Fatal("client2 timed out waiting for event")
	}

	// Test Unregister
	hub.Unregister(client1)
	if count := hub.ConnectedClientsCount(userID); count != 1 {
		t.Fatalf("expected 1 connected client after unregister, got %d", count)
	}

	hub.Unregister(client2)
	if count := hub.ConnectedClientsCount(userID); count != 0 {
		t.Fatalf("expected 0 connected clients after unregister all, got %d", count)
	}
}

func TestHub_ConcurrentOperations(t *testing.T) {
	hub := NewHub()
	userID := uuid.New()
	var wg sync.WaitGroup

	// Register 50 concurrent clients
	clients := make([]*Client, 50)
	for i := 0; i < 50; i++ {
		clients[i] = &Client{
			ID:       uuid.New().String(),
			UserID:   userID,
			Platform: "web",
			Events:   make(chan *SyncEvent, 20),
		}
	}

	for i := 0; i < 50; i++ {
		wg.Add(1)
		go func(idx int) {
			defer wg.Done()
			hub.Register(clients[idx])
		}(i)
	}
	wg.Wait()

	if count := hub.ConnectedClientsCount(userID); count != 50 {
		t.Fatalf("expected 50 connected clients, got %d", count)
	}

	// Broadcast 10 events concurrently
	for i := 0; i < 10; i++ {
		wg.Add(1)
		go func(seq int) {
			defer wg.Done()
			hub.Broadcast(userID, &SyncEvent{
				Type:       "ping",
				ServerTime: time.Now().UTC(),
			})
		}(i)
	}
	wg.Wait()

	// Unregister all concurrently
	for i := 0; i < 50; i++ {
		wg.Add(1)
		go func(idx int) {
			defer wg.Done()
			hub.Unregister(clients[idx])
		}(i)
	}
	wg.Wait()

	if count := hub.ConnectedClientsCount(userID); count != 0 {
		t.Fatalf("expected 0 connected clients after concurrent unregister, got %d", count)
	}
}
