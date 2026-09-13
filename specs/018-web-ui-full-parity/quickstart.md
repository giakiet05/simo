# Quickstart Guide: Web UI Full Feature Parity

**Feature**: `018-web-ui-full-parity`
**Date**: 2026-09-13

This guide provides setup, run, and validation steps to verify the Web UI against all user stories and acceptance scenarios.

---

## 1. Prerequisites & Environment

- **Node.js**: >= 20.x (`node -v`)
- **Backend Go Server**: Running on `http://localhost:8080`
- **PostgreSQL Database**: Running locally or via Docker Compose

---

## 2. Start Services

### 2.1 Start Backend Go Server
```bash
cd apps/server
go run cmd/server/main.go
```
*Server starts on `http://localhost:8080`.*

### 2.2 Start Web UI Dev Server
```bash
cd apps/web
npm run dev
```
*Vite dev server starts on `http://localhost:5173`.*

---

## 3. End-to-End Validation Scenarios

### Scenario 1: Light & Dark Theme Toggle
1. Open `http://localhost:5173` in a browser.
2. Verify default background is crisp white (`#ffffff` / `#f8fafc`) with sharp dark text.
3. Click the Sun/Moon icon in the top right corner.
4. Verify the UI transitions instantly to slate dark theme.
5. Refresh the page and confirm the dark theme persists.

### Scenario 2: Transaction CRUD & Advanced Filtering
1. Navigate to **Transactions** page.
2. Click **+ Thêm giao dịch** (New Transaction).
3. Fill in Amount: `50,000`, Category: `Ăn uống`, Wallet: `Tiền mặt`, Note: `Bánh mì chảo`. Click Save.
4. Verify the transaction appears under the "Hôm nay" (Today) date section.
5. Test the filter bar: select Category `Ăn uống` and verify filtered results update immediately.
6. Test search: type `Bánh mì` into search bar and verify instant match.
7. Select the transaction checkbox and click **Xóa đã chọn** (Bulk delete) to confirm deletion.

### Scenario 3: Multi-Wallet & Transfer
1. Navigate to **Wallets** (Ví) page.
2. Click **+ Thêm ví** and create `Techcombank` with balance `5,000,000 VND`.
3. Click **Chuyển tiền** (Transfer) to move `500,000 VND` from `Techcombank` to `Ví Tiền mặt` with `0 VND` fee.
4. Verify `Techcombank` balance reduces to `4,500,000 VND` and `Ví Tiền mặt` balance increases.

### Scenario 4: Monthly Budget & Category Allocation
1. Navigate to **Budgets** (Ngân sách) page.
2. Set monthly overall budget to `10,000,000 VND`.
3. Set category budget for `Ăn uống` to `3,000,000 VND`.
4. Check that spending progress bars reflect existing transactions with color badges (<80% green, 80-100% orange, >100% red).

### Scenario 5: Saving Goals & Deposits
1. Navigate to **Saving Goals** (Mục tiêu tiết kiệm) page.
2. Create goal `Mua MacBook` with target `30,000,000 VND`.
3. Click **Nạp tiền** and deposit `5,000,000 VND` from `Techcombank`.
4. Verify goal progress updates to `16.7%` and `Techcombank` balance reflects the deduction.

### Scenario 6: Sổ Nợ (Loans & Debts)
1. Navigate to **Loans** (Sổ nợ) page.
2. Add contact `Nam`, record a "Cho vay" (Lend) entry of `2,000,000 VND`.
3. Record a repayment of `1,000,000 VND`.
4. Verify remaining receivable balance shows `1,000,000 VND`.

### Scenario 7: Data Export & Backup
1. Navigate to **Settings > Export & Backup**.
2. Click **Xuất Excel** (.xlsx) and **Xuất PDF** and verify files download properly.
3. Click **Tải bản sao lưu JSON** and verify complete JSON archive downloads.

### Scenario 8: Synchronization Verification
1. Observe the **Sync Status** indicator in the navigation header.
2. Click **Đồng bộ ngay** (Sync Now).
3. Verify the status displays "Đã đồng bộ" (Synced) with current timestamp.
