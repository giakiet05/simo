# Research: Saving Goals (Mục tiêu tiết kiệm / Hũ tích lũy)

**Feature**: `005-saving-goals`

## 1. Storage & Schema Migration Strategy

- **Decision**: Add 2 new SQLite tables (`saving_goals`, `saving_goal_logs`) via standard `DatabaseHelper` schema upgrade (v7).
- **Rationale**:
  - `saving_goals` stores milestone configuration (name, target amount, current amount, target date, color, icon, note, status).
  - `saving_goal_logs` maintains an audit trail of every deposit and withdrawal event, enabling users to review how and when they accumulated their savings.
  - Foreign key cascading deletion ensures that removing a goal automatically cleans up all associated deposit logs.
- **Alternatives Considered**:
  - *Storing logs as JSON array in `saving_goals.logs`*: Rejected because querying, aggregating, and paginating individual deposit records is slower and harder to index.

---

## 2. Pacing Calculation Algorithm (Smart Insights)

- **Decision**: Dynamic formula based on remaining amount and remaining time.
  - $\text{Remaining Amount} = \max(0, \text{Target Amount} - \text{Current Amount})$
  - If $\text{Target Date}$ is present:
    - $\text{Days Remaining} = \max(1, \text{Target Date} - \text{Today in days})$
    - $\text{Months Remaining} = \max(1, \frac{\text{Days Remaining}}{30.44})$
    - $\text{Recommended Monthly Saving} = \frac{\text{Remaining Amount}}{\text{Months Remaining}}$
- **Rationale**: Provides clear actionable guidance without overwhelming the user with complex interest formulas.

---

## 3. UI/UX Architecture

- **Decision**:
  - Dedicated **Saving Goals Screen** accessible from Dashboard Quick Hub and navigation.
  - Unified **Overview Header**: Total target vs Total saved across all active goals + Overall progress circle/bar.
  - Dynamic **Goal Cards** displaying custom category-style icons, color themes, percent progress bars, remaining target amounts, and deadline tags.
  - Interactive **Detail & History Screen** showing milestones, deposit/withdraw action buttons, and chronological log history.
- **Rationale**: Follows the existing clean card aesthetic of Simo (similar to the Loans and Budget screens) for a consistent user experience.

---

## 4. Backup & Export Integration

- **Decision**:
  - Integrate `saving_goals` and `saving_goal_logs` into `BackupSnapshot` (`version: 2` or backward-compatible v1 data payload).
  - Export saving goals as an additional sheet ("Mục tiêu tiết kiệm") in Excel workbook exports.
- **Rationale**: Guarantees zero data loss when users backup and restore their app data.
