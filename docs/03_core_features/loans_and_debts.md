# Sổ Ghi Nợ & Cho Vay (Debts & Loans)

Simo tích hợp sổ ghi nợ cá nhân (`LoansScreen`) để theo dõi các khoản tiền người khác mượn mình hoặc mình mượn người khác mà không bị lẫn lộn vào dòng tiền chi tiêu sinh hoạt hàng ngày.

---

## 1. Phân Loại Khoản Nợ

- **`lend` (Cho vay / Người khác nợ tôi)**: Là một tài sản phải thu.
- **`borrow` (Đi vay / Tôi nợ người khác)**: Là một nghĩa vụ phải trả.

---

## 2. Mô Hình Dữ Liệu Hai Cấp

1. **Hồ Sơ Khoản Nợ (`loan_contacts`)**:
   - `contact_name`: Tên người liên quan (ví dụ: Bạn Nam, Anh Hoàng, Ngân hàng).
   - `total_amount`: Tổng số tiền ban đầu của khoản nợ.
   - `remaining_amount`: Số tiền còn lại cần thu hoặc cần trả.
   - `status`: `active` (chưa thanh toán xong) hoặc `completed` (đã tất toán xong).
   - `due_date`: Hạn chót thanh toán (hỗ trợ nhắc nhở).
2. **Lịch Sử Trả Nợ (`loan_transactions`)**:
   - Mỗi lần trả hoặc thu một phần tiền nợ, hệ thống tạo bản ghi mới liên kết với `loan_id`.
   - Cập nhật số tiền còn lại:
     $$\text{remaining\_amount}_{\text{mới}} = \text{remaining\_amount}_{\text{cũ}} - \text{amount\_paid}$$
   - Nếu $\text{remaining\_amount} \le 0$, khoản nợ tự động chuyển sang trạng thái `completed`.

---

## 3. Tương Tác Với Ví Tiền

- Khi thu nợ (`lend`): Tiền được cộng vào một ví được chỉ định.
- Khi trả nợ (`borrow`): Tiền được trừ khỏi ví thanh toán.
