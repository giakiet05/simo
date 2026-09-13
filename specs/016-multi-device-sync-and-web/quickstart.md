# Quickstart & Verification Guide: Multi-Device Sync & Web

**Feature**: `016-multi-device-sync-and-web`
**Date**: 2026-09-12

---

## 1. Prerequisites & Environment Setup

### 1.1. PostgreSQL (Existing Container on Homeserver)
Configure your `.env` file in the `apps/server/` directory with the database credentials pointing to your homeserver:

```env
PORT=8080
DATABASE_URL=postgres://simo_user:simo_password@homeserver_ip:5432/simo_db?sslmode=disable
JWT_SECRET=super_secret_jwt_key_simo_2026
```

### 1.2. Run Database Migrations
Execute migration scripts against PostgreSQL:
```bash
cd apps/server
go run cmd/migrate/main.go up
```

---

## 2. Launching Services

### 2.1. Start Go Backend Service
```bash
cd apps/server
go run cmd/server/main.go
# Server listening on http://localhost:8080
```

### 2.2. Start Web Frontend Development Server
```bash
cd apps/web
npm install
npm run dev
# Web app running at http://localhost:5173
```

### 2.3. Run Mobile App
```bash
cd apps/mobile
flutter run
```

---

## 3. End-to-End Verification Scenarios

### Scenario 1: Push-Pull Sync with Two Simulated Mobile Devices
1. **Device A pushes new wallet & transaction**:
   ```bash
   curl -X POST http://localhost:8080/api/v1/sync \
     -H "Authorization: Bearer <TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{
       "last_synced_server_time": null,
       "device_id": "device-a",
       "mutations": {
         "wallets": [{
           "id": "11111111-1111-1111-1111-111111111111",
           "name": "Cash Wallet",
           "type": "cash",
           "initial_balance": 1000000,
           "is_default": true,
           "created_at": "2026-09-12T00:00:00Z",
           "updated_at": "2026-09-12T00:00:00Z"
         }],
         "transactions": [{
           "id": "22222222-2222-2222-2222-222222222222",
           "wallet_id": "11111111-1111-1111-1111-111111111111",
           "amount": 50000,
           "type": "expense",
           "transaction_date": "2026-09-12",
           "note": "Lunch",
           "created_at": "2026-09-12T00:00:00Z",
           "updated_at": "2026-09-12T00:00:00Z"
         }]
       }
     }'
   ```
   **Expected Outcome**: Returns HTTP 200 with `server_time = T1`.

2. **Device B pulls data created by Device A**:
   ```bash
   curl -X POST http://localhost:8080/api/v1/sync \
     -H "Authorization: Bearer <TOKEN>" \
     -H "Content-Type: application/json" \
     -d '{
       "last_synced_server_time": null,
       "device_id": "device-b",
       "mutations": {}
     }'
   ```
   **Expected Outcome**: Returns HTTP 200 with changes containing the `Cash Wallet` and `Lunch` transaction created by Device A.

---

### Scenario 2: Web App Data Reflection
1. Open `http://localhost:5173` in a web browser.
2. Sign in with the same account.
3. Verify that the Dashboard reflects the `Cash Wallet` balance (950,000 VND) and the `Lunch` expense.
4. Create a new transaction directly on the Web UI.
5. Trigger sync on Device A; verify the new transaction appears immediately in local SQLite.
