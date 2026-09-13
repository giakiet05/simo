package handler

import (
	"encoding/json"
	"fmt"
	"net/http"
	"time"

	"github.com/google/uuid"

	"simo-server/internal/middleware"
	"simo-server/internal/sse"
)

// SSEHandler handles real-time Server-Sent Events HTTP streaming requests.
type SSEHandler struct {
	hub *sse.Hub
}

// NewSSEHandler creates a new SSEHandler instance.
//
// @param hub *sse.Hub
// @returns *SSEHandler
func NewSSEHandler(hub *sse.Hub) *SSEHandler {
	return &SSEHandler{hub: hub}
}

// Events handles GET /api/v1/sync/events streaming requests.
//
// @param w http.ResponseWriter
// @param r *http.Request
func (h *SSEHandler) Events(w http.ResponseWriter, r *http.Request) {
	flusher, ok := w.(http.Flusher)
	if !ok {
		http.Error(w, "Streaming unsupported by response writer", http.StatusInternalServerError)
		return
	}

	// Disable write deadline for persistent streaming
	rc := http.NewResponseController(w)
	_ = rc.SetWriteDeadline(time.Time{})

	userID, err := middleware.MustGetUserID(r.Context())
	if err != nil {
		http.Error(w, "Unauthorized", http.StatusUnauthorized)
		return
	}

	clientID := r.URL.Query().Get("client_id")
	if clientID == "" {
		clientID = uuid.New().String()
	}
	platform := r.URL.Query().Get("platform")
	if platform == "" {
		platform = "generic"
	}

	// Set SSE headers
	w.Header().Set("Content-Type", "text/event-stream")
	w.Header().Set("Cache-Control", "no-cache")
	w.Header().Set("Connection", "keep-alive")
	w.Header().Set("X-Accel-Buffering", "no")

	client := &sse.Client{
		ID:       clientID,
		UserID:   userID,
		Platform: platform,
		Events:   make(chan *sse.SyncEvent, 16),
	}

	h.hub.Register(client)
	defer h.hub.Unregister(client)

	// Send initial "connected" event
	connectPayload, _ := json.Marshal(map[string]interface{}{
		"user_id":                userID.String(),
		"client_id":              clientID,
		"server_time":            time.Now().UTC().Format(time.RFC3339Nano),
		"heartbeat_interval_sec": 20,
	})
	fmt.Fprintf(w, "event: connected\ndata: %s\n\n", connectPayload)
	flusher.Flush()

	ticker := time.NewTicker(20 * time.Second)
	defer ticker.Stop()

	for {
		select {
		case <-r.Context().Done():
			return
		case <-ticker.C:
			// Send comment heartbeat to keep connection alive through proxies
			fmt.Fprintf(w, ": keepalive %s\n\n", time.Now().UTC().Format(time.RFC3339))
			flusher.Flush()
		case event, ok := <-client.Events:
			if !ok {
				return
			}
			eventData, err := json.Marshal(event)
			if err != nil {
				continue
			}
			fmt.Fprintf(w, "event: %s\ndata: %s\n\n", event.Type, eventData)
			flusher.Flush()
		}
	}
}
