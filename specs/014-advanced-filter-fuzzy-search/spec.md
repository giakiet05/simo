# Feature Specification: 014-advanced-filter-fuzzy-search

**Feature Branch**: `014-advanced-filter-fuzzy-search`

**Created**: 2026-09-04

**Status**: Draft

**Input**: User description: "nâng cấp bộ lọc á, hiện tại lọc hơi thô sơ. và chưa có cơ chế tìm kiếm luôn. tao muốn update bộ lọc ngon hơn và cơ chế tìm kiếm fuzzy cho nó xịn. Mày trình bày tinh năng trước đi để mình làm rõ và đưa kế hoạch triển khai. Nhớ là nút tìm kiếm và nút lọc là 2 nút, nhưng phối hợp với nhau nha, nghĩa là tìm kiếm trên data đã lọc."

## Clarifications

### Session 2026-09-04
- Q: Nút tìm kiếm và nút lọc phối hợp với nhau như thế nào? → A: Nút tìm kiếm và nút lọc là 2 nút điều khiển độc lập trên AppBar. Luồng xử lý dữ liệu hoạt động theo thứ tự: áp dụng các điều kiện Lọc (Filter) trước để tạo tập dữ liệu con, sau đó thực hiện Tìm kiếm mờ (Fuzzy Search) trên tập dữ liệu đã lọc đó (Pipeline: All Transactions → Filter → Fuzzy Search → Group & Display). Khi đổi bộ lọc trong lúc đang tìm kiếm, kết quả tự động cập nhật ngay trên tập dữ liệu mới.
- Q: Khi người dùng nhập từ khóa tìm kiếm, danh sách kết quả nên được sắp xếp và hiển thị theo thứ tự nào? → A: Gom nhóm theo thẻ ngày (Day Cards), giao dịch mới nhất lên đầu, đồng bộ 100% với giao diện hiện tại.
- Q: Bộ lọc theo Ví (Wallet Filter) nên cho phép người dùng chọn một ví duy nhất hay có thể chọn được nhiều ví cùng lúc? → A: Đa chọn (Multi-select), cho phép tích chọn 1 hoặc nhiều ví bất kỳ, mặc định là Tất cả ví.
- Q: Màn hình giao dịch có nên bổ sung thanh Quick Filter Chips (các chip cuộn ngang để lọc nhanh Ví, Thời gian, Loại) ngay dưới thanh tiêu đề/tìm kiếm không? → A: Có, hiển thị thanh Quick Filter Chips cuộn ngang mượt mà để lọc nhanh 1 chạm, có chip kèm badge đếm số bộ lọc mở Modal chi tiết.
- Q: Thanh tìm kiếm có nên hỗ trợ tự động nhận diện và chuyển đổi các từ khóa viết tắt số tiền phổ biến (như "50k", "1.5tr") không? → A: Có, hỗ trợ cả tìm kiếm chữ (Ghi chú, Danh mục, Ví) và tự động nhận diện viết tắt số tiền thông dụng ("k", "tr", "m").
- Q: Trong Modal bộ lọc, phần chọn thời gian tùy chỉnh nên hỗ trợ chọn theo Tháng/Năm cụ thể hay chọn theo Khoảng ngày (Date Range)? → A: Hỗ trợ cả hai: Chọn Tháng/Năm cụ thể (tái sử dụng MonthYearPickerModal chuẩn của app) HOẶC chọn theo Khoảng ngày tùy ý (Date Range).

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Tìm Kiếm Mờ Thông Minh (Fuzzy Search Đa Trường & Tiếng Việt Không Dấu) (Priority: P1)

Người dùng muốn nhanh chóng tìm lại các giao dịch cũ bằng cách gõ từ khóa tự nhiên vào thanh tìm kiếm: có thể gõ tiếng Việt không dấu (ví dụ "an uong", "xang xe", "luong"), gõ sai chính tả nhẹ (như "cf", "coffe"), hoặc tìm theo tên danh mục, tên ví, số tiền hay ghi chú, hệ thống đều nhận diện và trả về kết quả chính xác ngay lập tức.

**Why this priority**: Hiện tại người dùng chỉ có thể tìm chuỗi con khớp tuyệt đối trên ghi chú/số tiền, không tìm được theo danh mục hay tên ví và không hỗ trợ gõ không dấu. Đây là tính năng cốt lõi giúp tra cứu giao dịch nhanh chóng.

**Independent Test**: Mở thanh tìm kiếm, gõ "an trua" hoặc "cafe", hệ thống trả về chính xác các giao dịch thuộc danh mục "Ăn uống" hoặc có ghi chú "Ăn trưa", "Cà phê" bất kể dấu tiếng Việt hay chữ hoa chữ thường.

**Acceptance Scenarios**:
1. **Given** danh sách có giao dịch ghi chú "Ăn trưa bún bò" và danh mục "Ăn uống", **When** người dùng gõ "bun bo" hoặc "an uong", **Then** hệ thống hiển thị giao dịch đó với độ trễ dưới 100ms.
2. **Given** người dùng gõ từ khóa sai chính tả nhẹ (ví dụ "cafee" thay vì "cafe"), **When** thuật toán fuzzy search xử lý, **Then** hệ thống vẫn tìm thấy giao dịch có ghi chú "cafe".
3. **Given** người dùng gõ số tiền (ví dụ "50000" hoặc "50k"), **When** tìm kiếm, **Then** hệ thống trả về các giao dịch có số tiền 50.000 đ.

---

### User Story 2 - Nâng Cấp Modal Bộ Lọc Nâng Cao (Advanced Filter Sheet) (Priority: P2)

Người dùng muốn mở bộ lọc nâng cao để lọc giao dịch theo nhiều tiêu chí kết hợp: lọc theo một hoặc nhiều ví (ví dụ chỉ xem giao dịch từ ví MoMo hoặc Tài khoản ngân hàng), lọc đồng thời nhiều danh mục, lọc theo khoảng thời gian tùy chọn và khoảng số tiền (min/max).

**Why this priority**: Hiện tại bộ lọc chỉ cho chọn 1 danh mục duy nhất, không có lọc theo ví (dù app đã có tính năng đa ví) và các tùy chọn thời gian còn cứng nhắc.

**Independent Test**: Mở bộ lọc, chọn Ví "Tiền mặt", tích chọn 2 danh mục "Ăn uống" và "Mua sắm", bấm Áp dụng, danh sách giao dịch chỉ hiển thị đúng các giao dịch thỏa mãn đồng thời các điều kiện trên.

**Acceptance Scenarios**:
1. **Given** người dùng có nhiều ví, **When** vào bộ lọc và chọn Ví "Ngân hàng", **Then** danh sách chỉ hiển thị các giao dịch phát sinh từ ví đó.
2. **Given** người dùng muốn xem các khoản chi ăn uống và mua sắm, **When** chọn cả 2 danh mục trong bộ lọc, **Then** danh sách hiển thị giao dịch của cả 2 danh mục này.
3. **Given** người dùng đã chọn nhiều điều kiện lọc, **When** bấm nút "Đặt lại", **Then** toàn bộ bộ lọc trở về trạng thái mặc định ban đầu.

---

### User Story 3 - Thanh Quick Filter Chips (Lọc Nhanh Trực Quan Trên Đầu Danh Sách) (Priority: P3)

Người dùng muốn chuyển đổi nhanh các góc nhìn giao dịch mà không cần phải mở toàn bộ sheet bộ lọc to (ví dụ: các chip bấm nhanh [Tất cả ví ▾], [Tháng này ▾], [Khoản chi ▾] ngay dưới thanh tìm kiếm).

**Why this priority**: Tăng tốc độ thao tác người dùng lên 3-4 lần cho các nhu cầu lọc phổ biến nhất hằng ngày.

**Independent Test**: Chạm vào chip [Tất cả ví ▾], chọn ví "Tiền mặt", danh sách lọc ngay lập tức mà không cần mở modal phức tạp.

**Acceptance Scenarios**:
1. **Given** màn hình danh sách giao dịch, **When** người dùng bấm chip [Khoản chi], **Then** danh sách chuyển sang chỉ hiển thị chi tiêu và chip được highlight trạng thái active.
2. **Given** có các bộ lọc đang kích hoạt, **When** người dùng nhìn vào thanh lọc, **Then** badge số lượng bộ lọc đang áp dụng hiển thị rõ ràng cùng nút xóa nhanh bộ lọc (x).

---

### Edge Cases

- Khi từ khóa tìm kiếm không khớp với bất kỳ giao dịch nào: Hiển thị màn hình trống thân thiện với gợi ý "Không tìm thấy giao dịch nào phù hợp" kèm nút "Xóa tìm kiếm".
- Khi người dùng nhập khoảng tiền không hợp lệ (Min > Max): Tự động đảo giá trị hoặc thông báo trực quan, không để app bị crash hay trả về mảng rỗng vô lý.
- Khi người dùng gõ tiếng Việt đang dở dang (bộ gõ telex chưa hoàn thành ký tự): Fuzzy search không bị giật lag, hỗ trợ cả chuỗi đang gõ.
- Khi có hàng ngàn giao dịch: Tìm kiếm và lọc chạy trên bộ nhớ cục bộ mượt mà dưới 16ms, không gây đơ giao diện cuộn.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Hệ thống PHẢI cung cấp cơ chế Fuzzy Search đa trường trên: Ghi chú giao dịch, Tên danh mục, Tên ví, và Số tiền (bao gồm tự động nhận diện các ký hiệu số tiền viết tắt như "k", "tr", "m").
- **FR-002**: Hệ thống PHẢI hỗ trợ chuẩn hóa tiếng Việt không dấu (Vietnamese accent-insensitive matching) để người dùng gõ có dấu hay không dấu đều tìm ra kết quả như nhau.
- **FR-003**: Thuật toán Fuzzy Search PHẢI hỗ trợ dung sai gõ sai chính tả nhẹ (Levenshtein distance hoặc substring fuzzy scoring) để tìm đúng mục tiêu kể cả khi người dùng gõ nhầm 1-2 ký tự.
- **FR-004**: Bộ lọc PHẢI hỗ trợ lọc đa Ví (Multi-wallet selection): Cho phép người dùng chọn Tất cả ví hoặc tích chọn đồng thời một hoặc nhiều ví bất kỳ (Set<String> walletIds).
- **FR-005**: Bộ lọc PHẢI hỗ trợ lọc đa Danh Mục (Multi-category selection) dạng lưới chip trực quan với icon và tên danh mục.
- **FR-006**: Bộ lọc PHẢI hỗ trợ lọc theo Loại giao dịch (Tất cả, Thu nhập, Chi tiêu).
- **FR-007**: Bộ lọc PHẢI hỗ trợ lọc Thời gian linh hoạt gồm: Các mốc sẵn (Hôm nay, Tuần này, Tháng này, Tháng trước, Năm nay), chọn Tháng/Năm cụ thể (tái sử dụng MonthYearPickerModal chuẩn của app với giới hạn từ tháng đầu tiên đến tháng hiện tại), và chọn Khoảng ngày tùy ý (Date Range).
- **FR-008**: Bộ lọc PHẢI hỗ trợ lọc theo Khoảng số tiền (Min amount - Max amount).
- **FR-009**: Hệ thống PHẢI cung cấp thanh Quick Filter Chips trên giao diện danh sách để lọc nhanh các điều kiện phổ biến.
- **FR-010**: Hệ thống PHẢI hiển thị huy hiệu (badge) đếm số lượng bộ lọc đang được áp dụng và cung cấp nút "Đặt lại" để xóa toàn bộ bộ lọc về mặc định một chạm.
- **FR-011**: Nút Tìm kiếm và nút Lọc PHẢI là 2 nút riêng biệt trên AppBar; khi cùng kích hoạt, Tìm kiếm mờ PHẢI thực hiện tuần tự trên tập dữ liệu đã lọc (Pipeline: All Transactions → Filter Criteria → Fuzzy Search → Display).
- **FR-012**: Kết quả tìm kiếm mờ PHẢI duy trì cấu trúc gom nhóm theo từng ngày (Day Cards) với thứ tự thời gian giảm dần (mới nhất lên đầu), đồng bộ với giao diện danh sách giao dịch chính.

### Key Entities

- **TransactionFilterCriteria**: Đối tượng chứa toàn bộ tiêu chí lọc hiện thời (searchQuery, walletIds, categoryIds, transactionType, dateRange, minAmount, maxAmount).
- **FuzzyMatchResult**: Đối tượng kết quả so khớp gồm điểm số độ tương đồng (score) và các trường khớp để xếp thứ tự ưu tiên giao dịch hiển thị.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Tốc độ phản hồi tìm kiếm mờ (Fuzzy Search) dưới 100ms trên tập dữ liệu hơn 1.000 giao dịch.
- **SC-002**: Tỷ lệ tìm kiếm thành công với tiếng Việt không dấu đạt 100% (ví dụ "luong", "ca phe", "an uong" đều tìm ra đúng giao dịch tương ứng).
- **SC-003**: Người dùng có thể hoàn thành việc lọc giao dịch theo ví và danh mục trong vòng dưới 5 giây.
- **SC-004**: Thao tác đặt lại bộ lọc đưa toàn bộ danh sách về trạng thái gốc tức thì trong 1 chạm.

## Assumptions

- Thuật toán fuzzy search chạy hoàn toàn trên client (Dart logic) không phụ thuộc backend hay dịch vụ bên ngoài, bảo đảm offline 100%.
- Người dùng đã có dữ liệu danh mục và ví trong máy để phục vụ việc lọc.
- Giữ nguyên toàn bộ cấu trúc Card giao dịch và Header ngày/tháng đã hoàn thiện trước đó.
