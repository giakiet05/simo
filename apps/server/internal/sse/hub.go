package sse

import (
	"sync"
	"time"

	"github.com/google/uuid"
)

// SyncEvent represents a real-time notification payload sent over SSE.
type SyncEvent struct {
	Type           string    `json:"type"`                      // e.g. "connected", "data_changed", "ping"
	SourceClientID string    `json:"source_client_id,omitempty"` // client ID that originated the event
	TableNames     []string  `json:"table_names,omitempty"`
	ServerTime     time.Time `json:"server_time"`
}

// Client represents an active connected SSE client stream.
type Client struct {
	ID       string
	UserID   uuid.UUID
	Platform string
	Events   chan *SyncEvent
}

// Hub manages active SSE client connections and dispatches events.
type Hub struct {
	mu      sync.RWMutex
	clients map[uuid.UUID]map[*Client]struct{}
}

// NewHub initializes and returns a new thread-safe Hub instance.
//
// @returns *Hub
func NewHub() *Hub {
	return &Hub{
		clients: make(map[uuid.UUID]map[*Client]struct{}),
	}
}

// Register adds a client connection to the hub under their user ID.
//
// @param c *Client
func (h *Hub) Register(c *Client) {
	if c == nil {
		return
	}

	h.mu.Lock()
	defer h.mu.Unlock()

	if _, exists := h.clients[c.UserID]; !exists {
		h.clients[c.UserID] = make(map[*Client]struct{})
	}
	h.clients[c.UserID][c] = struct{}{}
}

// Unregister removes a client connection from the hub and closes its channel.
//
// @param c *Client
func (h *Hub) Unregister(c *Client) {
	if c == nil {
		return
	}

	h.mu.Lock()
	defer h.mu.Unlock()

	if userClients, exists := h.clients[c.UserID]; exists {
		if _, found := userClients[c]; found {
			delete(userClients, c)
			close(c.Events)
		}
		if len(userClients) == 0 {
			delete(h.clients, c.UserID)
		}
	}
}

// Broadcast dispatches a sync event to all active clients of the specified user.
//
// @param userID uuid.UUID
// @param event *SyncEvent
func (h *Hub) Broadcast(userID uuid.UUID, event *SyncEvent) {
	if event == nil {
		return
	}

	h.mu.RLock()
	defer h.mu.RUnlock()

	userClients, exists := h.clients[userID]
	if !exists {
		return
	}

	for client := range userClients {
		select {
		case client.Events <- event:
		default:
			// Non-blocking drop if client buffer is saturated
		}
	}
}

// ConnectedClientsCount returns the number of active stream clients for a user.
//
// @param userID uuid.UUID
// @returns int
func (h *Hub) ConnectedClientsCount(userID uuid.UUID) int {
	h.mu.RLock()
	defer h.mu.RUnlock()

	return len(h.clients[userID])
}
