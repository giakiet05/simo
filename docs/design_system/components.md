# Component Patterns: SIMO Design System

Tài liệu này hướng dẫn chi tiết cách xây dựng và tái sử dụng các thành phần giao diện chuẩn trong SIMO.

---

## 🔝 1. Thanh tiêu đề trang (AppBar Pattern)

### Quy tắc:
1. `elevation: 0` (phẳng hoàn toàn).
2. Nút tạo mới/thêm dữ liệu chính (`+`) **bắt buộc đặt ở góc trên bên phải (`actions`)** của AppBar, không dùng FloatingActionButton ở góc dưới để tránh xung đột với Banner Ad.

### Mẫu chuẩn:
```dart
AppBar(
  title: Text(l10n.savingGoals),
  elevation: 0,
  actions: [
    IconButton(
      icon: const Icon(Icons.add),
      tooltip: l10n.addSavingGoal,
      onPressed: () => _openAddModal(context),
    ),
  ],
)
```

---

## 📊 2. Thẻ Tổng quan (Hero Overview Card)

### Quy tắc:
1. Đặt ở đầu màn hình danh sách để cung cấp cái nhìn tổng thể về số liệu (Tổng mục tiêu, Tổng đã gom, Tổng ngân sách, Tổng nợ).
2. Bo góc `20dp`, nền màu chủ đạo làm mờ `0.05`, viền mỏng `0.2`.
3. Bố cục 2 phần: Bên trái hiển thị số tiền nổi bật (20sp Bold), bên phải hiển thị biểu đồ tròn `CircularProgressIndicator` hoặc tỷ lệ %.

### Mẫu chuẩn:
```dart
Card(
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(20),
    side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
  ),
  color: theme.colorScheme.primary.withValues(alpha: 0.05),
  child: Padding(
    padding: const EdgeInsets.all(18),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.totalSaved, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              const SizedBox(height: 2),
              Text('${numberFormat.format(totalSaved)} $currencySymbol',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
              const SizedBox(height: 6),
              Text('${l10n.totalTarget}: ${numberFormat.format(totalTarget)} $currencySymbol',
                  style: TextStyle(fontSize: 12, color: theme.textTheme.bodySmall?.color)),
            ],
          ),
        ),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: CircularProgressIndicator(
                value: overallPercent,
                strokeWidth: 6,
                backgroundColor: Colors.grey.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
            Text('${(overallPercent * 100).toStringAsFixed(1)}%',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ],
        ),
      ],
    ),
  ),
)
```

---

## 🏷️ 3. Hàng Chip Bộ lọc chống tràn (Horizontal Filter Chips)

### ⚠️ QUY TẮC BẮT BUỘC:
Không bao giờ đặt các `ChoiceChip` trực tiếp trong `Row` đơn thuần vì sẽ bị lỗi **RenderFlex Overflow** trên màn hình nhỏ hoặc khi đổi sang ngôn ngữ dài.
**Luôn bọc `Row` trong `SingleChildScrollView(scrollDirection: Axis.horizontal)`**.

### Mẫu chuẩn:
```dart
SingleChildScrollView(
  scrollDirection: Axis.horizontal,
  child: Row(
    children: [
      _buildFilterChip('all', l10n.allGoals, totalCount),
      const SizedBox(width: 8),
      _buildFilterChip('in_progress', l10n.goalInProgress, inProgressCount),
      const SizedBox(width: 8),
      _buildFilterChip('completed', l10n.goalCompleted, completedCount),
    ],
  ),
)
```

---

## 💳 4. Thẻ Danh sách (List Item Card)

### Quy tắc:
1. `elevation: 0`, bo góc `16dp`, viền mờ `0.15 - 0.20`.
2. Phía bên trái là Icon Squircle bo góc `12dp` với nền màu nhạt `0.15`.
3. Bọc toàn bộ thẻ trong `InkWell(borderRadius: BorderRadius.circular(16), onTap: ...)` để hỗ trợ hiệu ứng gợn sóng khi chạm.
4. Tích hợp thanh tiến độ `LinearProgressIndicator` (nếu có hạn mức/mục tiêu) với độ cao tối thiểu `8dp`.

### Mẫu chuẩn:
```dart
Card(
  elevation: 0,
  margin: const EdgeInsets.only(bottom: 12),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(16),
    side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
  ),
  child: InkWell(
    borderRadius: BorderRadius.circular(16),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(iconData, color: color, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
              Text('$percent%', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    ),
  ),
)
```

---

## 💰 5. Ô nhập Tiền tệ có Dấu phẩy (Currency Input Formatter)

### Quy tắc:
1. Mọi ô nhập tiền tệ **bắt buộc** dùng `CurrencyInputFormatter` để tự động định dạng `1,000,000` theo thời gian thực.
2. Thiết lập bàn phím số: `keyboardType: TextInputType.number`.
3. Khi đọc/lưu giá trị: Luôn loại bỏ dấu phẩy trước khi parse: `double.tryParse(controller.text.replaceAll(',', '').trim())`.

### Mã định dạng chuẩn:
```dart
class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String clean = newValue.text.replaceAll(',', '');
    final number = int.tryParse(clean);
    if (number == null) return oldValue;

    final formatted = NumberFormat('#,###').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
```

---

## 📱 6. Modal BottomSheet nhập liệu (Form BottomSheet)

### Quy tắc:
1. Bo góc đỉnh `20dp`: `shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20)))`.
2. Bắt buộc thêm `isScrollControlled: true` và `padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom)` để tự động đẩy form lên khi bàn phím mở.
3. Nút hành động chính ở chân form: `ElevatedButton`, chiều rộng `double.infinity`, chiều cao `48 - 50dp`, bo góc `12dp`.

---

## 🏜️ 7. Màn hình Trống (Empty State)

### Quy tắc:
1. Căn giữa màn hình `Column(mainAxisAlignment: MainAxisAlignment.center)`.
2. Icon lớn (50 - 60dp) đặt trong Container tròn làm mờ `0.1`.
3. Tiêu đề in đậm (18sp Bold) + Mô tả phụ giải thích lợi ích (13sp Grey).
4. Nút bấm tạo mới để kích thích người dùng hành động.

---

## 📢 8. Tích hợp Quảng cáo Banner (Banner Ad Integration)

### Quy tắc:
Mọi màn hình danh sách độc lập đều kết thúc bằng `const BannerAdWidget()` ở đáy màn hình:
```dart
Scaffold(
  appBar: AppBar(...),
  body: Column(
    children: [
      Expanded(
        child: ListView(...),
      ),
      const BannerAdWidget(),
    ],
  ),
)
```
