# Data Model: Data Export & Backup

## 1. Export Filter Parameters (`ExportFilterParams`)

Configuration model representing user selections for reporting timeframes:

```dart
class ExportFilterParams {
  final ExportDateRange rangeType; // thisMonth, lastMonth, thisYear, custom, allTime
  final DateTime? startDate;
  final DateTime? endDate;
  final String? typeFilter; // all, income, expense
  final String currency;

  const ExportFilterParams({
    required this.rangeType,
    this.startDate,
    this.endDate,
    this.typeFilter,
    required this.currency,
  });
}
```

---

## 2. Backup Snapshot Schema (`BackupSnapshot`)

Complete JSON container structure for export and restore:

```json
{
  "version": 1,
  "app": "simo",
  "app_version": "1.3.0",
  "exported_at": "2026-08-22T07:00:00.000Z",
  "data": {
    "settings": {
      "currency": "VND",
      "language": "vi",
      "theme": "system",
      "monthly_budget": 0.0
    },
    "categories": [
      {
        "id": "uuid",
        "name": "Ăn uống",
        "type": "expense",
        "icon": "restaurant",
        "color": "#FF5722",
        "budget_limit": 5000000.0,
        "created_at": "2026-08-01T00:00:00.000Z",
        "updated_at": "2026-08-01T00:00:00.000Z"
      }
    ],
    "transactions": [
      {
        "id": "uuid",
        "category_id": "uuid",
        "recurring_config_id": null,
        "amount": 50000.0,
        "formula": null,
        "note": "Cà phê sáng",
        "type": "expense",
        "transaction_date": "2026-08-21T08:30:00.000Z",
        "created_at": "2026-08-21T08:30:00.000Z",
        "updated_at": "2026-08-21T08:30:00.000Z"
      }
    ],
    "monthly_budgets": [
      {
        "id": "uuid",
        "year": 2026,
        "month": 8,
        "amount": 15000000.0,
        "created_at": "2026-08-01T00:00:00.000Z",
        "updated_at": "2026-08-01T00:00:00.000Z"
      }
    ],
    "category_monthly_budgets": [
      {
        "id": "uuid",
        "category_id": "uuid",
        "year": 2026,
        "month": 8,
        "amount": 5000000.0,
        "created_at": "2026-08-01T00:00:00.000Z",
        "updated_at": "2026-08-01T00:00:00.000Z"
      }
    ],
    "loan_contacts": [
      {
        "id": "uuid",
        "contact_name": "Nguyễn Văn A",
        "type": "borrowed",
        "total_amount": 2000000.0,
        "remaining_amount": 1000000.0,
        "status": "active",
        "created_at": "2026-08-10T00:00:00.000Z",
        "updated_at": "2026-08-10T00:00:00.000Z"
      }
    ],
    "loan_transactions": [
      {
        "id": "uuid",
        "loan_id": "uuid",
        "amount": 1000000.0,
        "type": "borrowed",
        "date": "2026-08-10T00:00:00.000Z",
        "due_date": null,
        "note": "Mượn tiền đóng học phí",
        "created_at": "2026-08-10T00:00:00.000Z",
        "updated_at": "2026-08-10T00:00:00.000Z"
      }
    ],
    "recurring_configs": [
      {
        "id": "uuid",
        "category_id": "uuid",
        "name": "Tiền mạng Internet",
        "amount": 250000.0,
        "type": "expense",
        "frequency": "monthly",
        "interval": 1,
        "day_of_month": 15,
        "next_run": "2026-09-15T00:00:00.000Z",
        "is_active": 1,
        "created_at": "2026-08-01T00:00:00.000Z",
        "updated_at": "2026-08-01T00:00:00.000Z"
      }
    ]
  }
}
```

---

## 3. Import Summary Inspection Model (`ImportInspection`)

Model displayed in the UI modal before confirming restore:

```dart
class ImportInspection {
  final int schemaVersion;
  final DateTime exportedAt;
  final int totalCategories;
  final int totalTransactions;
  final int totalMonthlyBudgets;
  final int totalLoans;
  final int totalRecurringConfigs;
  final bool isValid;
  final String? errorMessage;

  const ImportInspection({
    required this.schemaVersion,
    required this.exportedAt,
    required this.totalCategories,
    required this.totalTransactions,
    required this.totalMonthlyBudgets,
    required this.totalLoans,
    required this.totalRecurringConfigs,
    this.isValid = true,
    this.errorMessage,
  });
}
```

---

## 4. Entity Restoration Dependency Hierarchy

To maintain SQLite foreign key integrity:
1. `categories` (referenced by transactions, recurring_configs, category_monthly_budgets)
2. `monthly_budgets`
3. `category_monthly_budgets` (references categories)
4. `recurring_configs` (references categories)
5. `loan_contacts` (referenced by loan_transactions)
6. `loan_transactions` (references loan_contacts)
7. `transactions` (references categories, recurring_configs)
8. `settings` (currency, language, theme)
