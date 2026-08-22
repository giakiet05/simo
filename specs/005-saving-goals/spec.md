# Feature Specification: Saving Goals (Mục tiêu tiết kiệm / Hũ tích lũy)

**Feature Branch**: `005-saving-goals`

**Created**: 2026-08-22

**Status**: Draft

**Input**: User description: "thêm mục tiêu tiết kiệm"

---

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Create & Manage Saving Goals (Priority: P1)

As a user who wants to build disciplined financial habits, I want to create, edit, view, and organize saving goals with target amounts, target dates, custom icons, and colors, so that I can clearly visualize what I am saving for (e.g., buying a laptop, emergency fund, vacation).

**Why this priority**: Creating and managing saving goals is the foundational capability. Without goal definitions, users cannot track or deposit money towards their milestones.

**Independent Test**: Can be tested by creating various saving goals with different target amounts, target dates, icons, and color themes, editing their details, archiving or deleting goals, and verifying they appear correctly in the Saving Goals list and dashboard overview.

**Acceptance Scenarios**:

1. **Given** the user is on the Saving Goals screen, **When** they tap the "+" button, **Then** a creation form appears allowing them to input the goal name, target amount, optional deadline (target date), color, icon, and optional notes.
2. **Given** an existing saving goal, **When** the user edits the goal details (e.g., updates the target amount from 15,000,000 to 20,000,000 VND or extends the deadline), **Then** the changes are saved immediately and reflected in the goal cards and progress calculations.
3. **Given** a goal the user no longer needs, **When** they choose to delete the goal, **Then** a confirmation prompt is displayed warning that associated deposit/withdraw histories will also be removed upon confirmation.

---

### User Story 2 - Deposit & Withdraw Funds with History Logs (Priority: P1)

As a user accumulating savings, I want to deposit money into a goal or withdraw funds when needed, and review a complete history of deposits and withdrawals, so that I maintain full accountability over my progress.

**Why this priority**: Tracking incoming deposits and withdrawals is the core transactional mechanic of a saving goal.

**Independent Test**: Can be tested by depositing an amount into a goal, verifying the current saved amount and percentage update immediately, withdrawing a partial amount, and reviewing the detailed chronological history of all deposit/withdraw records.

**Acceptance Scenarios**:

1. **Given** an active saving goal with 2,000,000 VND current savings, **When** the user deposits 1,000,000 VND with a note "Thưởng tháng", **Then** the goal's current amount increases to 3,000,000 VND, the progress bar updates, and a deposit log entry is recorded with date, amount, and note.
2. **Given** a saving goal, **When** the user withdraws an amount less than or equal to the current saved amount, **Then** the goal balance decreases accordingly and a withdrawal log entry is created.
3. **Given** the user enters a deposit amount that causes the current amount to reach or exceed the target amount (100%), **Then** the goal status automatically updates to "Completed" with a congratulatory visual badge.

---

### User Story 3 - Visual Progress Tracking & Smart Insights (Priority: P2)

As a goal-oriented user, I want to see visual progress indicators (% completed, remaining amount needed, days remaining) and smart calculation insights (e.g., amount needed to save per month/week to meet the deadline), so that I stay motivated and stay on track.

**Why this priority**: Visual progress and intelligent pacing insights drive motivation and help users plan realistic monthly allocations.

**Independent Test**: Can be tested by setting a goal with a deadline 5 months in the future, checking that the app displays the progress percentage, remaining balance, and computes the required monthly savings rate correctly.

**Acceptance Scenarios**:

1. **Given** a saving goal with target 12,000,000 VND and deadline in 6 months, **When** viewing the goal details, **Then** the app calculates and shows the remaining amount needed (e.g., 9,000,000 VND) and recommended monthly deposit pace (e.g., 1,500,000 VND/month).
2. **Given** a list of saving goals (some in progress, some completed), **When** viewing the Saving Goals screen, **Then** goals are grouped or filterable by status (Đang tích lũy, Đã hoàn thành) with overall total saved summary at the top.

---

### User Story 4 - Data Backup & Export Integration (Priority: P3)

As a user using the backup and export system, I want my saving goals and transaction histories to be included in full JSON backup snapshots and Excel export workbooks, so that my savings milestones are safely preserved.

**Why this priority**: Maintains consistency with the app's backup, restore, and reporting architecture.

**Independent Test**: Can be tested by exporting a JSON backup containing saving goals, clearing data, restoring the backup, and verifying all goals and deposit histories are restored intact.

**Acceptance Scenarios**:

1. **Given** saving goals and deposit logs in the database, **When** the user generates a JSON backup, **Then** `saving_goals` and `saving_goal_logs` are serialized into the snapshot.
2. **Given** a backup containing saving goals, **When** restoring with Overwrite or Merge mode, **Then** goals and logs are properly restored without foreign key constraint errors.

---

## Key Entities *(mandatory)*

- **SavingGoal**:
  - `id`: Unique identifier (UUID)
  - `name`: Name of the goal (e.g. "Mua MacBook Air M3")
  - `targetAmount`: Total monetary target to achieve (> 0)
  - `currentAmount`: Current accumulated amount (default: 0.0)
  - `targetDate`: Optional target deadline date
  - `color`: Hex color string or color code
  - `icon`: Icon identifier string
  - `note`: Optional description or motivation note
  - `status`: Goal state (`active`, `completed`, `paused`)
  - `createdAt`: Timestamp created
  - `updatedAt`: Timestamp updated

- **SavingGoalLog**:
  - `id`: Unique identifier (UUID)
  - `goalId`: Foreign key to `SavingGoal`
  - `amount`: Monetary amount deposited (+) or withdrawn (-)
  - `type`: `deposit` or `withdraw`
  - `logDate`: Timestamp of the transaction
  - `note`: Optional note describing the deposit/withdrawal
  - `createdAt`: Timestamp created

---

## Success Criteria *(mandatory)*

1. **Effortless Goal Creation**: Users can create a new saving goal in under 15 seconds with minimal input (name + target amount).
2. **Instant Deposit/Withdrawal**: Depositing or withdrawing funds updates the goal balance, progress bar, and logs instantly with 0 latency.
3. **100% Goal Completion Recognition**: Goals automatically reflect completed status with clear visual feedback when target is reached.
4. **Data Integrity & Portability**: 100% of saving goals and logs are included in JSON backups and can be restored with zero data loss.
5. **Clear Financial Insights**: Users can clearly see their total savings across all goals and remaining balance required at a single glance.
