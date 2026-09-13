# Quickstart & Verification Guide: Live Sync (SSE)

**Feature**: `019-sse-live-sync`
**Date**: 2026-09-13
**Status**: Approved

This guide defines end-to-end verification procedures to validate that real-time live synchronization operates correctly across Go backend, React Web UI, and Flutter Mobile App.

---

## 1. Prerequisites & Environment Setup

Ensure backend and web containers are running inside Docker:
```bash
docker compose up -d --build
```

Verify backend health:
```bash
curl -i http://localhost:8080/health
```

---

## 2. Automated Tests Execution (Docker First)

Run backend sync and SSE broker test suite inside the test container:
```bash
docker compose run --rm simo-server go test -v ./test/sync_test.go ./test/sse_test.go
```

Run web unit tests for sync service and live sync:
```bash
docker compose run --rm simo-web npm test
```

---

## 3. End-to-End Multi-Device Live Sync Scenarios

### Scenario 1: Go SSE Stream Connection Test
**Objective**: Verify the SSE stream handshake, keepalive, and authentication.

1. Connect to the SSE endpoint using `curl`:
   ```bash
   curl -N -H "Accept: text/event-stream" "http://localhost:8080/api/v1/sync/events?token=dev_token&client_id=curl-client-1"
   ```
2. **Expected Output**:
   ```text
   event: connected
   data: {"user_id":"00000000-0000-0000-0000-000000000001","client_id":"curl-client-1","server_time":"...","heartbeat_interval_sec":20}
   ```
3. Keep the terminal open to observe incoming broadcasts.

---

### Scenario 2: Mutation Broadcast & Echo Suppression
**Objective**: Verify that submitting a mutation on Client A broadcasts a `data_changed` event to Client B while suppressing echo on Client A.

1. In Terminal 1, keep the SSE stream open for Client B (`curl-client-2`):
   ```bash
   curl -N "http://localhost:8080/api/v1/sync/events?token=dev_token&client_id=client-b"
   ```
2. In Terminal 2, perform a mutation push representing Client A (`client-a`):
   ```bash
   curl -X POST http://localhost:8080/api/v1/sync \
     -H "Authorization: Bearer dev_token" \
     -H "Content-Type: application/json" \
     -d '{
       "device_id": "client-a",
       "mutations": {
         "wallets": [{
           "id": "e2e-wallet-test-01",
           "name": "Live Sync Test Wallet",
           "type": "cash",
           "initial_balance": 500000,
           "currency": "VND",
           "icon": "wallet",
           "color": "#10B981",
           "is_default": false,
           "exclude_from_total": false,
           "priority": 1,
           "created_at": "2026-09-13T14:00:00Z",
           "updated_at": "2026-09-13T14:00:00Z"
         }]
       }
     }'
   ```
3. **Observation on Terminal 1 (Client B)**:
   ```text
   event: data_changed
   data: {"source_client_id":"client-a","table_names":["wallets"],"server_time":"..."}
   ```

---

### Scenario 3: Web UI Live Auto-Refresh
1. Open `http://localhost:3000` in Browser Window 1.
2. Open `http://localhost:3000` in Browser Window 2 (or a separate tab/incognito window).
3. In Window 1, create a new transaction of `50,000 VND`.
4. **Result**: Within 1.5 seconds, Window 2 receives the SSE event, executes a background pull, and updates its Dashboard balance and Transactions list without page reload.
