# Quickstart & Verification Guide: ReAct AI Agent Architecture with Full CRUD

**Feature**: `022-react-agent-full-crud`

This guide outlines runnable scenarios to verify end-to-end functionality of the ReAct agent, multi-turn clarification, full CRUD entity operations, and dual-sync loan management.

---

## 1. Automated Unit & Integration Tests

Run the full suite of Agent tests:

```bash
cd apps/mobile
flutter test test/unit/agent_tools_test.dart test/unit/ai_action_test.dart
```

Run linter validation:
```bash
flutter analyze lib/agent/ lib/providers/ai_assistant_provider.dart
```

---

## 2. Manual End-to-End Verification Scenarios

### Scenario A: Multi-turn Clarification (Slot-Filling)
1. Open the Simo AI Assistant screen.
2. Type or speak: `"Tạo khoản cho mượn 500k"` (Missing contact name).
3. **Verify Outcome**:
   - Agent does NOT create any database records.
   - Agent responds asking: *"Bạn cho ai mượn 500.000đ vậy để mình lưu vào Sổ Nợ nhé?"*.
4. Reply: `"Cho anh Hùng mượn bằng ví Momo"`.
5. **Verify Outcome**:
   - Agent resumes intent and creates a LoanContact for "anh Hùng" with 500.000đ.
   - Sổ nợ displays 500.000đ owed by anh Hùng.
   - Giao dịch tab displays an expense of -500.000đ under system category `sys_loan_lend`.
   - MoMo wallet balance decreases by 500.000đ.

---

### Scenario B: Full CRUD Wallet & Budget Operations
1. Chat: `"Đổi tên ví Momo thành MoMo Chi Tiêu và đặt làm ví mặc định"` $\to$ Verify wallet name and default badge update immediately in Wallets screen.
2. Chat: `"Tăng ngân sách ăn uống tháng này lên 4 triệu"` $\to$ Verify progress bar limit updates in Budgets screen.
3. Chat: `"Xóa hạn mức mua sắm tháng này đi"` $\to$ Verify shopping budget limit is cleared.

---

### Scenario C: Pre-condition Validation (ReAct Observation Loop)
1. Set Cash wallet balance to `100.000 VND`.
2. Chat: `"Chuyển 1 triệu từ Tiền mặt sang MoMo"`.
3. **Verify Outcome**:
   - Tool execution fails with `insufficient balance`.
   - Agent captures the observation and explains: *"Ví Tiền mặt của bạn hiện chỉ còn 100.000đ, không đủ số dư để chuyển 1.000.000đ sang MoMo"*.
   - No funds are transferred.

---

### Scenario D: Multi-action Compound Execution
1. Chat: `"Sáng nay ăn phở 40k tiền mặt rồi chuyển khoản cho mẹ 2 củ từ VCB"`.
2. **Verify Outcome**:
   - Expense of 40.000đ recorded from Cash wallet.
   - Expense/Transfer of 2.000.000đ recorded from VCB wallet.
   - Single assistant response confirming both actions.
