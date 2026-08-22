# Data Model: Transaction Dates and Timestamps

## Entities

### `Transaction` Entity

Represents an income, expense, or transfer transaction record in SQLite and in-memory Riverpod state.

| Field | Type | Required | Description | Validation & Rules |
|---|---|---|---|---|
| `id` | String (UUID) | Yes | Unique identifier of the transaction | Primary Key |
| `categoryId` | String? | No | Foreign key to Category | Nullable for uncategorized transactions |
| `recurringConfigId` | String? | No | Foreign key to RecurringConfig | Nullable |
| `amount` | double | Yes | Monetary amount of the transaction | Must be > 0 |
| `formula` | String? | No | Optional arithmetic formula entered by user | Nullable |
| `note` | String? | No | Description or note for transaction | Nullable |
| `type` | String | Yes | Transaction type: `'expense'`, `'income'`, `'loan_in'`, `'loan_out'`, etc. | Non-empty |
| `transactionDate` | DateTime | Yes | Date and time when the actual financial transaction took place | Used for sorting, grouping by month, and filtering. Defaults to chosen date or `DateTime.now()` on creation. |
| `createdAt` | DateTime | Yes | Date and time when record was originally created | Immutable after creation. |
| `updatedAt` | DateTime | Yes | Date and time when record was last updated | Updated to `DateTime.now()` on every edit. |

---

## Serialization & Persistence Mapping

### SQLite Mapping (`transactions` table)

| Column Name | SQLite Type | Constraints | Mapping Logic |
|---|---|---|---|
| `id` | TEXT | PRIMARY KEY | `id` |
| `category_id` | TEXT | | `categoryId` |
| `recurring_config_id` | TEXT | | `recurringConfigId` |
| `amount` | REAL | NOT NULL | `amount` |
| `formula` | TEXT | | `formula` |
| `note` | TEXT | | `note` |
| `type` | TEXT | NOT NULL | `type` |
| `transaction_date` | TEXT | | `transactionDate.toIso8601String()`. Fallback on load: `map['transaction_date'] != null ? DateTime.parse(map['transaction_date']) : DateTime.parse(map['created_at'])` |
| `created_at` | TEXT | NOT NULL | `createdAt.toIso8601String()` |
| `updated_at` | TEXT | NOT NULL | `updatedAt.toIso8601String()`. Fallback on load: `map['updated_at'] != null ? DateTime.parse(map['updated_at']) : DateTime.parse(map['created_at'])` |

---

## State Lifecycle & Transitions

```
[Create Transaction]
   │
   ├── transactionDate = userSelectedDate ?? now()
   ├── createdAt = now()
   └── updatedAt = now()
   
[Update Transaction]
   │
   ├── transactionDate = userSelectedDate ?? existing.transactionDate ?? existing.createdAt
   ├── createdAt = existing.createdAt (UNCHANGED)
   └── updatedAt = now() (REFRESHED)
```
