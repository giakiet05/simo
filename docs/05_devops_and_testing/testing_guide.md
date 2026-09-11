# Hướng Dẫn Kiểm Thử (Testing & Quality Assurance Guide)

Mọi tính năng mới hoặc bản sửa lỗi (bugfix) trong Simo đều phải đi kèm Unit Test hoặc Widget Test nhằm đảm bảo độ tin cậy và ngăn ngừa lỗi hồi quy (regression).

---

## 1. Cấu Trúc Thư Mục Kiểm Thử (`test/`)

```text
test/
├── unit/                           # Kiểm thử logic tầng Repository và Service
│   ├── category_repository_test.dart
│   └── wallet_repository_test.dart
├── widget_category_form_test.dart  # Kiểm thử UI widget và tương tác modal
└── mocks/                          # Mock objects và dữ liệu mẫu
```

---

## 2. Kỹ Thuật Kiểm Thử SQLite Với FFI (In-Memory Database Testing)

Để chạy Unit Test trên máy tính lập trình (Linux / macOS / Windows) mà không cần mở máy ảo Android hoặc iOS, ta sử dụng package `sqflite_common_ffi`.

### Đoạn mã thiết lập chuẩn trong mọi file Test:
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:simo/repositories/database_helper.dart';

void main() {
  setUpAll(() {
    // Khởi tạo FFI SQLite runtime cho môi trường máy bàn
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(() async {
    // Luôn dọn dẹp sạch sẽ database sau mỗi test case
    await DatabaseHelper.instance.clearAllData();
  });

  test('Ví dụ kiểm thử tạo ví...', () async {
    // Thực thi test...
  });
}
```

---

## 3. Quy Tắc Vàng: Chạy Test Với `--concurrency=1`

Do SQLite engine sử dụng khóa tệp (file lock), nếu Flutter chạy song song nhiều file test cùng lúc trên một database, lỗi `database is locked (code 5)` sẽ xảy ra.

> [!IMPORTANT]
> **Lệnh Chạy Test Chuẩn**:
> ```bash
> # Chạy toàn bộ test suite với 1 luồng duy nhất
> flutter test --concurrency=1
> 
> # Chạy một file test cụ thể
> flutter test test/unit/wallet_repository_test.dart
> ```

---

## 4. Kiểm Tra Chất Lượng Mã Nguồn (Linter & Static Analysis)

Trước khi commit code, luôn chạy công cụ phân tích tĩnh của Flutter:
```bash
flutter analyze
```
Quy chuẩn: **0 errors, 0 warnings**. Toàn bộ các cảnh báo deprecated hoặc unused imports phải được giải quyết triệt để.
