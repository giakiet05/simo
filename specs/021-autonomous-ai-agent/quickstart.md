# Quickstart Validation Guide: Autonomous AI Agent

**Feature**: [spec.md](./spec.md) | **Date**: 2026-09-17

## Prerequisites
- Valid OpenAI API Key configured in `.env` (`AI_API_KEY=sk-...` or `OPENAI_API_KEY=sk-...`)
- `AI_MODEL=gpt-4o-mini`

---

## Scenario 1: Interactive Data View Cards (Generative UI)
1. Open the AI Assistant screen by tapping the center navigation button on the Home bar.
2. Say or type: `"Cho tao xem hôm nay tao đã tiêu những gì?"`
3. **Expected Result**:
   - AI replies with a conversational summary.
   - An interactive `TransactionListCard` is rendered in chat showing today's expense items with category icons and amounts.
   - Tapping any transaction opens its edit/detail dialog.

---

## Scenario 2: Full Mutation Tool Execution (Budget & Wallet)
1. In the AI Assistant chat, say or type: `"Đặt ngân sách ăn uống tháng này là 3 triệu"`
2. **Expected Result**:
   - `budget_set` tool executes.
   - A confirmation card appears displaying the updated Food & Dining budget limit.
3. Say or type: `"Tạo ví mới MB Bank số dư 5 triệu"`
4. **Expected Result**:
   - `wallet_create` tool executes.
   - App state updates, creating a new wallet with 5.000.000 VND balance.

---

## Scenario 3: 10-Turn Working Context Memory & Horizon Divider
1. Engage in a multi-turn conversation of > 10 messages.
2. **Expected Result**:
   - A clean divider `──── 🧠 AI ghi nhớ từ đây (10 tin gần nhất) ────` appears dynamically above message index `total - 10`.
3. In turn 11, say: `"Sửa khoản vừa thêm thành 40k"`
4. **Expected Result**:
   - AI correctly references the transaction created in turn 10 and updates it.

---

## Scenario 4: App Navigation Deep Linking
1. Say or type: `"Mở màn hình báo cáo thống kê"`
2. **Expected Result**:
   - AI replies: `"Tôi đang mở màn hình báo cáo thống kê cho bạn..."`
   - App automatically transitions to the Reports/Analytics screen.
