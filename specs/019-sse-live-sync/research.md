# Research & Technical Decisions: Real-Time Live Sync (SSE)

**Feature**: `019-sse-live-sync`
**Date**: 2026-09-13
**Status**: Approved

---

## 1. Streaming Protocol Selection: SSE vs WebSocket vs Polling

### Decision
We choose **Server-Sent Events (SSE)** over standard HTTP streaming (`text/event-stream`) for real-time notification delivery from the Go backend to Web and Mobile clients.

### Rationale
- **Lightweight & HTTP/2 Native**: SSE operates over standard HTTP/1.1 or HTTP/2 GET requests without protocol upgrade headers (`101 Switching Protocols`).
- **Unidirectional Match**: Simo's sync model is inherently unidirectional for notifications: server notifies clients $\to$ clients execute standard delta pull. Bidirectional streaming (WebSocket) is unnecessary overhead since all mutations already use the robust, atomic `POST /api/v1/sync` endpoint.
- **Built-in Browser Support**: Web browsers natively support `EventSource` with automatic reconnection, event IDs, and lifecycle management.
- **Firewall & Proxy Compatibility**: SSE traverses enterprise proxies, CDN layers, and cloud firewalls without being blocked or requiring specialized WebSocket tunnel configuration.
- **Mobile Battery Friendliness**: Unlike WebSockets which require complex client-side ping/pong frames and connection health state machines, SSE can be cleanly opened when the app enters foreground and severed when backgrounded.

### Alternatives Considered
| Protocol | Pros | Cons | Verdict |
| :--- | :--- | :--- | :--- |
| **WebSocket** | Full-duplex bidirectional streaming. | High state management complexity, separate auth handshake, requires heartbeat ping-pong, high mobile battery drain if unmanaged. | **Rejected**: Over-engineering for notification-only needs. |
| **Short/Long Polling** | Simple implementation. | High server request volume, high network overhead, latency jitter (5-30s delay). | **Rejected**: Inefficient and lacks instant UX. |
| **Webhooks** | Server-to-server standard. | Infeasible for mobile/browser clients (cannot receive inbound HTTP connections). | **Rejected**: Not applicable for client apps. |
| **Server-Sent Events (SSE)** | Minimal overhead, native HTTP, automatic reconnect, clean disconnect semantics. | Unidirectional (server $\to$ client only). | **Selected**: Perfect fit for Simo's push-first pull-second architecture. |

---

## 2. Event Payload Design: Thin Signal vs Thick Payload

### Decision
We implement a **Thin Event Signal** architecture. SSE messages will transmit minimal metadata (`event_type: "data_changed"`, `source_client_id`, `server_time`, and optional entity hints) rather than transmitting full record diffs over the event stream.

### Rationale
- **Single Source of Truth**: The existing `POST /api/v1/sync` engine handles database transactions, tombstone deletions, dependency ordering (e.g. Wallets before Transactions), and last-write-wins conflict arbitration.
- **Consistency & Ordering**: Transmitting database mutations directly over SSE risks out-of-order delivery, packet loss during stream reconnection, or schema divergence.
- **Simplicity & Reliability**: When a client receives `data_changed`, it debounces and executes a standard delta pull. If 50 updates occur in 1 second, the client performs 1 single delta pull to catch up completely.

---

## 3. Echo Prevention & Debounce Strategy

### Decision
- **Echo Suppression**: Every sync request and SSE connection supplies a `device_id` / `client_id`. When Device A performs a mutation, the Go server broadcasts `source_client_id: "Device A"`. Device A discards the event, preventing redundant self-pulls.
- **Client-Side Debouncing**: When receiving `data_changed` from another client, receiving devices wait **300ms** before initiating the pull. Rapid successive mutations are aggregated into a single HTTP roundtrip.

---

## 4. Authentication Strategy for SSE Stream

### Decision
Support dual authentication pathways on `GET /api/v1/sync/events`:
1. `Authorization: Bearer <jwt_token>` header (used by Flutter mobile app, curl, and automated tests).
2. `?token=<jwt_token>` query parameter (used by browser `EventSource` which lacks native custom header support).

### Rationale
Native browser `EventSource` does not support custom HTTP headers. Allowing the validated JWT token in the query string enables native `EventSource` usage in React without requiring bulky third-party polyfills.

---

## 5. Mobile & Web Lifecycle Management

### Decision
- **Web App**:
  - `EventSource` is active while tab is open.
  - Listen to `document.visibilitychange` and `window.onfocus` to trigger an immediate catch-up sync when user returns to an inactive tab.
- **Mobile App (Flutter)**:
  - SSE stream connects when `AppLifecycleState.resumed`.
  - SSE stream explicitly cancels/closes on `AppLifecycleState.paused`, `inactive`, or `detached`.
  - Immediate catch-up delta sync executes upon entering `resumed`.
