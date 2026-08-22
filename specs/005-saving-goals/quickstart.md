# Quickstart & Validation Guide: Saving Goals

**Feature**: `005-saving-goals`

## Validation Scenarios

### Scenario 1: Create a Saving Goal
1. Open Simo app and navigate to **Mục tiêu tiết kiệm** (Saving Goals).
2. Tap the **+** (Tạo mục tiêu) button.
3. Enter Name: "Mua Macbook Air", Target: `30,000,000` VND, Deadline: 6 months from now, select Teal color and Laptop icon.
4. Save the goal.
5. **Expected Outcome**: The goal card is created with 0% progress and 30,000,000 VND remaining.

### Scenario 2: Deposit Funds into Goal
1. Tap on the "Mua Macbook Air" goal card to open detail view.
2. Tap **Nạp tiền** (Deposit).
3. Enter Amount: `5,000,000` VND, Note: "Tiền tiết kiệm tháng 8".
4. Submit.
5. **Expected Outcome**:
   - Current amount becomes `5,000,000` VND (16.7%).
   - Deposit history log appears in the timeline.
   - Recommended monthly pace recalculates to `5,000,000` VND/month.

### Scenario 3: Complete a Goal
1. Deposit `25,000,000` VND into the goal.
2. **Expected Outcome**:
   - Current amount reaches `30,000,000` VND (100%).
   - Status transitions to "Đã hoàn thành" with completion badge.

### Scenario 4: Backup & Restore
1. Go to **Cài đặt -> Xuất & Sao lưu dữ liệu -> Sao lưu & Khôi phục**.
2. Tap **Tạo bản sao lưu**.
3. Reset data in app.
4. Tap **Khôi phục dữ liệu** and select the saved backup file.
5. **Expected Outcome**: "Mua Macbook Air" goal and all deposit history logs are restored 100% intact.
