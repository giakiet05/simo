# Cơ Chế Cơ Sở Dữ Liệu & Repository Pattern

Tài liệu này giải thích chi tiết cách `DatabaseHelper` quản lý kết nối SQLite, bảo toàn tính đơn nguyên (ACID) thông qua Database Transactions, và cách các Repository tương tác với tầng lưu trữ.

---

## 1. `DatabaseHelper` Singleton

Lớp `DatabaseHelper` (`lib/repositories/database_helper.dart`) được thiết kế theo mẫu Singleton nhằm đảm bảo chỉ có **duy nhất một connection pool** được mở tới tệp `simo.db` trong toàn bộ vòng đời ứng dụng.

```dart
class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('simo.db');
    return _database!;
  }
}
```

### Các phương thức trọng yếu:
- `_initDB(String filePath)`: Mở database với version 16, đăng ký callback `_createDB` và `_upgradeDB`.
- `clearAllData()`: Xóa sạch toàn bộ dữ liệu trong tất cả 11 bảng khi người dùng chọn "Đặt lại dữ liệu" hoặc khi chạy test teardown. Thao tác này được bọc trọn vẹn trong một `db.transaction()` và tự động khởi tạo lại một ví tiền mặt mặc định (`default_cash_wallet`) với số dư 0.
- `close()`: Đóng connection khi kết thúc phiên làm việc.

---

## 2. Tính Đơn Nguyên & An Toàn Dữ Liệu (ACID & Transactions)

Trong các nghiệp vụ có nhiều bước cập nhật đồng thời, việc sử dụng `db.transaction()` là bắt buộc để tránh tình trạng "treo" số dư hoặc mất dữ liệu khi ứng dụng bị crash giữa chừng.

### 2.1. Chuyển Tiền Giữa 2 Ví (`WalletRepository.transferFunds`)
Khi chuyển số tiền $A$ từ Ví nguồn sang Ví đích với phí $F$:
1. Tạo bản ghi trong `wallet_transfers`.
2. Trừ $A + F$ khỏi số dư Ví nguồn.
3. Cộng $A$ vào số dư Ví đích.
4. **Không tạo Transaction thu/chi thông thường** để tránh tính trùng vào tổng chi tiêu tháng của người dùng.

```dart
Future<void> transferFunds({
  required String sourceWalletId,
  required String destinationWalletId,
  required double amount,
  double fee = 0.0,
  required DateTime date,
  String? note,
}) async {
  final db = await _dbHelper.database;
  await db.transaction((txn) async {
    // 1. Ghi nhận giao dịch chuyển tiền
    await txn.insert('wallet_transfers', transfer.toMap());

    // 2. Trừ tiền ví nguồn
    await txn.rawUpdate('''
      UPDATE wallets 
      SET current_balance = current_balance - ?, updated_at = ? 
      WHERE id = ?
    ''', [amount + fee, now, sourceWalletId]);

    // 3. Cộng tiền ví đích
    await txn.rawUpdate('''
      UPDATE wallets 
      SET current_balance = current_balance + ?, updated_at = ? 
      WHERE id = ?
    ''', [amount, now, destinationWalletId]);
  });
}
```

### 2.2. Xóa Danh Mục An Toàn (Soft-Unlink on Delete)
Khác với hành vi `ON DELETE CASCADE` làm mất trắng toàn bộ lịch sử giao dịch của người dùng, Simo áp dụng cơ chế **chuyển giao dịch về trạng thái Không có danh mục**:

```dart
Future<void> deleteCategory(String categoryId) async {
  final db = await _dbHelper.database;
  await db.transaction((txn) async {
    // 1. Chuyển toàn bộ giao dịch liên quan về NULL category_id
    await txn.update(
      'transactions',
      {'category_id': null},
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );

    // 2. Xóa hạn mức tháng của danh mục này
    await txn.delete(
      'category_monthly_budgets',
      where: 'category_id = ?',
      whereArgs: [categoryId],
    );

    // 3. Xóa danh mục
    await txn.delete(
      'categories',
      where: 'id = ?',
      whereArgs: [categoryId],
    );
  });
}
```

---

## 3. Quản Lý Đồng Thời & Kỷ Luật Test (Concurrency Discipline)

SQLite sử dụng cơ chế khóa tệp (file-locking). Khi chạy các bài kiểm thử tự động (Unit Test / Widget Test) trên máy chủ hoặc môi trường Linux bằng `sqflite_common_ffi`, việc nhiều worker truy cập đồng thời vào database có thể gây ra lỗi:
`DatabaseException: database is locked (code 5)`.

> [!IMPORTANT]
> **Kỷ luật chạy Test**:
> Luôn chạy `flutter test` với cờ `--concurrency=1` khi test các file có tương tác trực tiếp với SQLite database:
> ```bash
> flutter test --concurrency=1 test/unit/category_repository_test.dart test/unit/wallet_repository_test.dart
> ```
