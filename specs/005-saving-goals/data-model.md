# Data Model: Saving Goals (Mục tiêu tiết kiệm / Hũ tích lũy)

**Feature**: `005-saving-goals`

## Entities

### 1. SavingGoal

Represents a financial milestone target.

| Field | Type | SQLite Column | Description |
|-------|------|---------------|-------------|
| `id` | String | `id TEXT PRIMARY KEY` | UUID v4 identifier |
| `name` | String | `name TEXT NOT NULL` | Name of the goal (e.g., "Mua Laptop") |
| `targetAmount` | double | `target_amount REAL NOT NULL` | Target amount to save (> 0) |
| `currentAmount` | double | `current_amount REAL NOT NULL DEFAULT 0` | Accumulated amount so far |
| `targetDate` | DateTime? | `target_date TEXT` | Optional deadline timestamp (ISO8601) |
| `color` | String | `color TEXT` | Hex color string (e.g., `#4CAF50`) |
| `icon` | String | `icon TEXT` | Icon code name (e.g., `laptop`, `flight`, `savings`) |
| `note` | String? | `note TEXT` | Optional motivation or goal note |
| `status` | String | `status TEXT NOT NULL DEFAULT 'active'` | `active`, `completed`, `paused` |
| `createdAt` | DateTime | `created_at TEXT NOT NULL` | Creation timestamp |
| `updatedAt` | DateTime | `updated_at TEXT NOT NULL` | Last update timestamp |

**Computed Properties**:
- `progressPercentage`: `(currentAmount / targetAmount).clamp(0.0, 1.0)`
- `remainingAmount`: `(targetAmount - currentAmount).clamp(0.0, double.infinity)`
- `isCompleted`: `currentAmount >= targetAmount || status == 'completed'`
- `isOverdue`: `targetDate != null && DateTime.now().isAfter(targetDate!) && !isCompleted`

---

### 2. SavingGoalLog

Represents an individual deposit or withdrawal record against a goal.

| Field | Type | SQLite Column | Description |
|-------|------|---------------|-------------|
| `id` | String | `id TEXT PRIMARY KEY` | UUID v4 identifier |
| `goalId` | String | `goal_id TEXT NOT NULL` | Foreign key referencing `saving_goals(id)` |
| `amount` | double | `amount REAL NOT NULL` | Positive amount of transaction |
| `type` | String | `type TEXT NOT NULL` | `deposit` (nạp tiền) or `withdraw` (rút tiền) |
| `logDate` | DateTime | `log_date TEXT NOT NULL` | Date when funds were moved |
| `note` | String? | `note TEXT` | Optional reason/note |
| `createdAt` | DateTime | `created_at TEXT NOT NULL` | Timestamp created |

---

## Relationships

```
┌───────────────────────────┐
│        SavingGoal         │
│  - id (PK)                │
│  - name                   │
│  - target_amount          │
│  - current_amount         │
│  - target_date            │
└─────────────┬─────────────┘
              │ 1
              │
              │ has many (ON DELETE CASCADE)
              │
              ▼ N
┌───────────────────────────┐
│       SavingGoalLog       │
│  - id (PK)                │
│  - goal_id (FK)           │
│  - amount                 │
│  - type (deposit/withdraw)│
│  - log_date               │
└───────────────────────────┘
```
