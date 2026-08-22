# SIMO Design System & UI Guidelines

Chào mừng bạn đến với tài liệu hướng dẫn thiết kế giao diện và trải nghiệm người dùng (**Simo Design System**). Tài liệu này đóng vai trò là **Nguồn chân lý duy nhất (Single Source of Truth)** cho toàn bộ phong cách thị giác, cấu trúc thành phần và quy tắc tương tác trong ứng dụng SIMO.

---

## 🎯 Mục tiêu & Triết lý thiết kế

1. **Gọn gàng & Hiện đại (Clean & Modern Flat UI)**:
   - Sử dụng bề mặt phẳng (Elevation 0) kết hợp viền mờ (`BorderSide(color: Colors.grey.withValues(alpha: 0.15 - 0.2))`) để phân cách nội dung thay vì đổ bóng đậm.
   - Bo góc mềm mại từ 12dp đến 20dp tạo cảm giác thân thiện.

2. **Tiện dụng & Tối ưu một tay (Mobile First & Thumb-Friendly)**:
   - Các nút thao tác chính (Create / Add) đặt trên thanh AppBar (góc trên phải) hoặc trong Modal BottomSheet.
   - Toàn bộ danh sách bộ lọc ngang (Filter Chips) luôn được bọc chống tràn (`SingleChildScrollView(scrollDirection: Axis.horizontal)`).

3. **Số liệu rõ ràng & Nhập liệu thông minh (Smart Data Formatting)**:
   - Tất cả các ô nhập tiền và hiển thị số tiền đều áp dụng định dạng phân cách hàng nghìn bằng dấu phẩy (`1,000,000`).
   - Màu sắc ngữ nghĩa phản ánh đúng bản chất dòng tiền (Xanh lá = Thu nhập/Nạp tiền, Đỏ/Cam = Chi tiêu/Rút tiền, Xanh dương = Thông tin/Thống kê, Hổ phách = Cảnh báo).

4. **Sẵn sàng cho Dark Mode & Đa ngôn ngữ**:
   - Màu nền và màu chữ tuân theo Color Tokens hỗ trợ cả Light Mode và Dark Mode.
   - Chuỗi văn bản linh hoạt chiều dài trên 3 ngôn ngữ (Tiếng Việt, Tiếng Anh, Tiếng Trung).

---

## 📚 Cấu trúc bộ tài liệu

| Tài liệu | Mô tả nội dung |
|----------|----------------|
| [**1. Design Tokens (`tokens.md`)**](tokens.md) | Bảng màu (Core, Semantic, Category Palette), Typography, Hệ thống lưới 8dp, Bo góc (Radii), Độ nổi (Elevation) & Dark Mode. |
| [**2. Reusable Components (`components.md`)**](components.md) | Quy chuẩn AppBar, Card tổng quan (Hero), Card danh sách, Chip cuộn ngang, Ô nhập tiền dấu phẩy, BottomSheet, Empty state, Banner Ads. |
| [**3. Screen Audit (`screen_audit.md`)**](screen_audit.md) | Đánh giá hiện trạng 9 màn hình trong app & danh sách các điểm cần chuẩn hóa. |
| [**4. Screen Recipes & Boilerplates (`recipes.md`)**](recipes.md) | Mã nguồn mẫu Flutter cho các màn hình CRUD, Form BottomSheet, Master-Detail để copy & phát triển nhanh. |
