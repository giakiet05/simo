# Giao Dịch & Danh Mục Thu Chi (Transactions & Categories)

---

## 1. Giao Dịch (Transactions)

### 1.1. Các Loại Giao Dịch
- **`expense` (Chi tiêu)**: Giảm số dư ví tương ứng, tính vào tiến độ hạn mức tháng của danh mục.
- **`income` (Thu nhập)**: Tăng số dư ví tương ứng, không tính vào hạn mức chi tiêu.

### 1.2. Trải Nghiệm Nhập Liệu Tối Ưu (Form UX)
Màn hình tạo giao dịch `TransactionFormScreen` được thiết kế để thao tác nhanh nhất có thể:
1. **Ô nhập số tiền lớn**: Tự động định dạng hàng nghìn theo thời gian thực (ví dụ: `50,000`), hỗ trợ gõ biểu thức toán học tính nhẩm cơ bản (ví dụ: `25000+15000`).
2. **Thanh chọn ví nằm ngang (`WalletChipSelector`)**: Sắp xếp ví theo độ ưu tiên `priority`, cho phép vuốt ngang chọn ví chỉ bằng 1 chạm mà không cần mở popup.
3. **Thanh chọn ngày nhanh (`DateQuickBar`)**: Ba nút tiện lợi: *Hôm nay*, *Hôm qua*, và *Chọn ngày khác* trên lịch.
4. **Lưới danh mục trực quan (`CategoryGridPicker`)**: Lưới icon phân màu rõ rệt, hỗ trợ chuyển đổi nhanh giữa tab Thu và Chi.

### 1.3. Nhập Liệu Bằng Giọng Nói & Trí Tuệ Nhân Tạo (AI Voice Input)
- Nhấn giữ nút Microphone trên màn hình chính để nói: *"Hôm nay ăn trưa hết 45 nghìn bằng tiền mặt"*.
- `SpeechToText` chuyển audio thành chuỗi văn bản.
- `AiTransactionService` gửi prompt có cấu trúc tới mô hình ngôn ngữ để bóc tách:
  - `amount`: 45000
  - `type`: "expense"
  - `category`: "Ăn uống"
  - `wallet`: "Tiền mặt"
  - `date`: Ngày hôm nay.
- Hệ thống tự động điền form và mở modal xác nhận trước khi lưu.

---

## 2. Danh Mục (Categories)

### 2.1. Phân Loại Danh Mục
1. **Danh mục Hệ thống (System Categories)**:
   - Có `id` bắt đầu bằng `sys_` (ví dụ: `sys_food`, `sys_salary`).
   - Không thể xóa để bảo toàn tính toàn vẹn của các thống kê cốt lõi.
   - Người dùng có thể đổi màu sắc, icon và hạn mức.
2. **Danh mục Tùy chỉnh (Custom Categories)**:
   - Do người dùng tự tạo với icon và bảng màu tự chọn.
   - Có thể xóa bất kỳ lúc nào.

### 2.2. Cơ Chế Xóa Danh Mục An Toàn
Khi người dùng xóa một danh mục:
- Toàn bộ giao dịch trong quá khứ liên kết với danh mục này sẽ được gán `category_id = NULL` (hiển thị trên giao diện là **"Không có danh mục"**).
- Không bao giờ xóa giao dịch (`NO CASCADE DELETE`), đảm bảo số dư ví và tổng tiền không bị lệch sau khi xóa danh mục.
