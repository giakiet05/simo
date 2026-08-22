# Contracts: Build Configuration & Mock Generator Interfaces

## 1. Gradle Build Configuration Contract (`android/app/build.gradle.kts`)

```kotlin
android {
    defaultConfig {
        applicationId = "com.simolab.simo"
        manifestPlaceholders["appName"] = "Simo"
    }

    buildTypes {
        debug {
            applicationIdSuffix = ".dev"
            manifestPlaceholders["appName"] = "Simo Dev"
        }
        release {
            manifestPlaceholders["appName"] = "Simo"
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}
```

---

## 2. Mock Generator Service Contract (`MockDataGenerator`)

```dart
class MockDataGenerator {
  final CategoryRepository _categoryRepo;
  final LoanRepository _loanRepo;

  MockDataGenerator(this._categoryRepo, this._loanRepo);

  /// Generates categories, loans, and transactions from March to August 2026.
  Future<void> generateRichMockData({bool clearExisting = false});
}
```

---

## 3. Settings UI Trigger Contract (`SettingsScreen`)

- UI Section: **Dữ liệu & Phát triển (Data & Developer)**
- Action Item: **Tạo dữ liệu mẫu (Generate Mock Data)**
  - Prompts confirmation dialog: "Tạo dữ liệu mẫu từ tháng 3 đến tháng 8/2026?"
  - On confirm: Executes `MockDataGenerator.generateRichMockData()`
  - Calls `ref.read(transactionProvider.notifier).loadTransactions()`, `ref.read(categoryProvider.notifier).loadCategories()`, `ref.read(loanProvider.notifier).loadLoans()`
  - Shows SnackBar: "Đã tạo thành công dữ liệu mẫu!"
