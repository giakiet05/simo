# Simo Monorepo

> **Simple Money Management** — Ứng dụng quản lý tài chính cá nhân đa nền tảng hiện đại theo triết lý **Offline-First & Privacy-First**, hỗ trợ đồng bộ dữ liệu đám mây đa thiết bị và giao diện quản lý trên Web.

---

## 1. Cấu Trúc Monorepo

```text
simo/
├── apps/
│   ├── mobile/     # 📱 Flutter Mobile App (iOS / Android) với SQLite Offline-First
│   ├── server/     # 🚀 Go Backend API Service (Push-First Pull-Second Sync Engine)
│   └── web/        # 💻 Web Management Dashboard (React 19 + TypeScript + Vite + Tailwind CSS)
├── docs/           # Tài liệu thiết kế & kiến trúc hệ thống
└── specs/          # Tài liệu đặc tả kỹ thuật tính năng (Spec-Kit)
```

---

## 2. Hướng Dẫn Khởi Chạy Từng Ứng Dụng

### 2.1. Go Backend Server (`apps/server`)
1. Cấu hình biến môi trường kết nối PostgreSQL homeserver:
   ```bash
   cd apps/server
   cp .env.example .env
   # Điền chuỗi DATABASE_URL trỏ tới PostgreSQL của bạn
   ```
2. Chạy migration tạo bảng dữ liệu:
   ```bash
   go run cmd/migrate/main.go
   ```
3. Khởi chạy HTTP API Server:
   ```bash
   go run cmd/server/main.go
   # Server lắng nghe tại http://localhost:8080
   ```

---

### 2.2. Web Management App (`apps/web`)
1. Cài đặt dependencies và khởi chạy dev server:
   ```bash
   cd apps/web
   npm install
   npm run dev
   # Ứng dụng Web mở tại http://localhost:5173
   ```

---

### 2.3. Mobile App (`apps/mobile`)
1. Cài đặt dependencies và chạy kiểm thử:
   ```bash
   cd apps/mobile
   flutter pub get
   flutter test --concurrency=1
   ```
2. Khởi chạy ứng dụng:
   ```bash
   flutter run
   ```

---

## 3. Kiến Trúc Đồng Bộ Đa Thiết Bị (Delta Sync Engine)
- **Hệ quy chiếu thời gian**: Sử dụng Server Clock (UTC) làm cursor duy nhất (`server_updated_at`), miễn nhiễm 100% với việc lệch giờ giữa các thiết bị ở các múi giờ khác nhau.
- **Quy trình 2 chiều**: **Push-First $\rightarrow$ Pull-Second** trong 1 Database Transaction đơn nguyên tại `POST /api/v1/sync`.
- **Giải quyết xung đột**: Last-Write-Wins (LWW) per-entity + Tombstone Soft Delete.
- **Số dư ví**: Được tính toán động từ biến động dòng tiền (Transactions & Transfers), đảm bảo hội tụ chính xác tuyệt đối trên mọi thiết bị.
