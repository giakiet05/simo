# Quản Lý Trạng Thái (State Management with Riverpod)

Simo sử dụng thư viện **Flutter Riverpod (v2.6+)** làm giải pháp quản lý trạng thái duy nhất. Riverpod cung cấp cơ chế Dependency Injection (DI) an toàn trong thời gian biên dịch (compile-time safety), hỗ trợ xử lý bất đồng bộ (`AsyncValue`) và quản lý vòng đời bộ nhớ hiệu quả.

---

## 1. Nguyên Tắc Tổ Chức Provider

1. **Một Chiều & Minh Bạch (Unidirectional Data Flow)**:
   - UI chỉ được đọc trạng thái thông qua `ref.watch(provider)` hoặc gọi hành động qua `ref.read(provider.notifier).method()`.
   - UI không bao giờ tự ý thay đổi trạng thái nội bộ của Provider một cách trực tiếp.
2. **Immutable State**:
   - Trạng thái trả về từ Provider luôn là các đối tượng bất biến (Immutable). Khi có cập nhật, Notifier sinh ra đối tượng state mới thay vì mutate state cũ.
3. **AsyncValue cho Dữ Liệu Bất Đồng Bộ**:
   - Mọi luồng đọc từ SQLite đều được bọc trong `AsyncValue<T>`:
     - `AsyncLoading`: Hiển thị loading skeleton / spinner.
     - `AsyncData`: Render dữ liệu thực tế khi truy vấn thành công.
     - `AsyncError`: Hiển thị thông báo lỗi kèm nút "Thử lại" (Retry).

---

## 2. Các Mẫu Provider Cốt Lõi (Core Provider Patterns)

### 2.1. Global Notifiers (CRUD cơ bản)
Dùng cho các tài nguyên dùng chung toàn ứng dụng như Danh mục, Ví, Danh bạ nợ.

```dart
// Ví dụ: CategoryNotifier quản lý danh sách danh mục
class CategoryNotifier extends StateNotifier<AsyncValue<List<Category>>> {
  final CategoryRepository _repository;

  CategoryNotifier(this._repository) : super(const AsyncValue.loading()) {
    loadCategories();
  }

  Future<void> loadCategories() async {
    try {
      final categories = await _repository.getAllCategories();
      state = AsyncValue.data(categories);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> createCategory(...) async {
    await _repository.createCategory(...);
    await loadCategories(); // Refresh lại state
  }
}
```

### 2.2. Parameterized Family Provider (`monthlyBudgetFamily`)
Đối với tính năng Ngân sách hàng tháng, mỗi tháng/năm có một ngân sách và trạng thái chi tiêu hoàn toàn tách biệt. Ta sử dụng `Family` provider kết hợp class định danh `MonthYearKey`:

```dart
class MonthYearKey {
  final int year;
  final int month;
  const MonthYearKey(this.year, this.month);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MonthYearKey && runtimeType == other.runtimeType && year == other.year && month == other.month;

  @override
  int get hashCode => year.hashCode ^ month.hashCode;
}

// Provider định nghĩa theo Family
final monthlyBudgetFamily = StateNotifierProvider.family<MonthlyBudgetNotifier, AsyncValue<MonthlyBudgetSummary>, MonthYearKey>(
  (ref, key) {
    final repository = ref.watch(monthlyBudgetRepositoryProvider);
    return MonthlyBudgetNotifier(repository, key.year, key.month);
  },
);
```
- **Lợi ích**: Khi người dùng chuyển qua lại giữa tháng 8, tháng 9, tháng 10, Riverpod sẽ tự động cache và quản lý riêng trạng thái của từng tháng mà không làm xáo trộn dữ liệu.

---

## 3. Quy Trình Vô Hiệu Hóa Bộ Nhớ Đệm (Cache Invalidation Flow)

Khi một giao dịch tài chính xảy ra, nhiều tầng dữ liệu độc lập sẽ bị ảnh hưởng. Simo thiết lập chuỗi invalidation chặt chẽ để đảm bảo UI luôn đồng bộ:

```mermaid
graph TD
    TX[Tạo / Sửa / Xóa Giao Dịch] --> InvalidateTX[ref.invalidate(transactionProvider)]
    TX --> InvalidateWallet[ref.invalidate(walletListProvider)]
    TX --> InvalidateTotal[ref.invalidate(totalBalanceProvider)]
    TX --> InvalidateBudget[ref.invalidate(monthlyBudgetFamily)]
    
    InvalidateWallet --> UI_Wallet[Cập nhật số dư ví trên Header]
    InvalidateTX --> UI_Recent[Cập nhật danh sách giao dịch gần đây]
    InvalidateBudget --> UI_Progress[Cập nhật thanh tiến độ chi tiêu tháng]
```

### Triển khai thực tế trong code:
```dart
Future<void> saveTransaction(Transaction tx) async {
  await _txRepo.createTransaction(tx);
  
  // Vô hiệu hóa cache để các Provider tự động nạp lại dữ liệu mới nhất từ SQLite
  ref.invalidate(transactionProvider);
  ref.invalidate(walletListProvider);
  ref.invalidate(totalBalanceProvider);
  ref.invalidate(monthlyBudgetFamily(MonthYearKey(tx.date.year, tx.date.month)));
}
```

---

## 4. Danh Sách Các Provider Chính Trong Ứng Dụng

| Provider Tên | Kiểu Trả Về | Trách Nhiệm |
| :--- | :--- | :--- |
| `walletListProvider` | `AsyncValue<List<Wallet>>` | Danh sách ví sắp xếp theo Priority giảm dần |
| `totalBalanceProvider` | `AsyncValue<double>` | Tổng số dư các ví (loại trừ ví bật `exclude_from_total`) |
| `categoriesProvider` | `AsyncValue<List<Category>>` | Toàn bộ danh mục thu và chi |
| `expenseCategoriesProvider` | `List<Category>` | Danh mục loại Chi tiêu |
| `incomeCategoriesProvider` | `List<Category>` | Danh mục loại Thu nhập |
| `transactionListProvider` | `AsyncValue<List<Transaction>>` | Danh sách giao dịch theo bộ lọc hiện tại |
| `monthlyBudgetFamily(key)`| `AsyncValue<MonthlyBudgetSummary>` | Tình hình ngân sách và hạn mức của tháng `key` |
| `savingGoalsProvider` | `AsyncValue<List<SavingGoal>>` | Danh sách mục tiêu tiết kiệm |
| `loanListProvider` | `AsyncValue<List<LoanContact>>` | Sổ nợ và danh bạ vay/cho vay |
| `settingsProvider` | `AsyncValue<Settings>` | Cấu hình Dark mode, Tiền tệ, Ngôn ngữ |
| `localizationProvider` | `Localization` | Quản lý chuỗi văn bản bản địa hóa (vi/en) |
