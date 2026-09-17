# Quickstart Validation Guide: Conversational AI Financial Assistant & Agent

**Feature**: `020-ai-assistant-agent`  
**Date**: 2026-09-17  
**Status**: Ready for Implementation  

---

## 1. Prerequisites & Environment Setup

Ensure your local `.env` file contains valid OpenAI credentials:

```dotenv
AI_BASE_URL=https://api.openai.com
AI_API_KEY=sk-your-openai-api-key
AI_MODEL=gpt-5-nano
WHISPER_BASE_URL=https://api.openai.com/v1
WHISPER_MODEL=whisper-1
USE_WHISPER=true
```

---

## 2. Validation Scenarios

### Scenario 1: Natural Text Chat - Record Expense
1. Open Simo app and tap the central AI Assistant button on the bottom navigation bar.
2. In the chat input bar, type:
   ```text
   Ăn sáng phở bò 45k bằng tiền mặt
   ```
3. Tap the **Send** button.
4. **Expected Outcome**:
   - User message bubble appears on the right.
   - Assistant displays a thinking indicator, then responds in natural Vietnamese:
     *"Tao đã ghi nhận khoản chi Ăn uống 45.000đ từ ví Tiền mặt rồi nhé!"*
   - An Action Card is rendered below the response showing:
     - Badge: **Chi tiêu**
     - Amount: **-45.000 ₫**
     - Subtitle: **Ăn sáng phở bò • Ăn uống • Tiền mặt**
   - The transaction is immediately saved in SQLite database.

---

### Scenario 2: Multi-Action Utterance via Speech
1. In the AI Assistant screen, tap the **Microphone** icon.
2. Speak clearly into the microphone:
   ```text
   Vừa đổ xăng năm chục và chuyển 200k từ Techcombank sang Momo
   ```
3. Tap the microphone icon again to stop (or wait 5s for auto-detection).
4. **Expected Outcome**:
   - Voice audio is uploaded to OpenAI Whisper API and transcribed accurately.
   - Assistant executes both actions atomically via `AiActionDispatcher`:
     1. Expense: 50.000 VND (Di chuyển / Xăng xe).
     2. Transfer: 200.000 VND from Techcombank to MoMo.
   - Assistant responds with two separate action confirmation cards.

---

### Scenario 3: Financial Inquiry & Context Awareness
1. In the chat input, type:
   ```text
   Hôm nay tao đã tiêu bao nhiêu rồi mày?
   ```
2. Tap Send.
3. **Expected Outcome**:
   - Assistant inspects the injected `AiFinancialContextSnapshot` (today's transactions total).
   - Assistant responds conversationally with the exact sum spent today (e.g. *"Hôm nay bạn đã chi tiêu tổng cộng 95.000đ (45k ăn sáng và 50k xăng xe)!"*).
   - No database mutations or action cards are generated.

---

### Scenario 4: Error Handling & Guided Recovery
1. In the chat input, enter an ambiguous or unhelpful phrase:
   ```text
   Alo 123
   ```
2. Tap Send.
3. **Expected Outcome**:
   - Assistant politely replies in Vietnamese guiding the user on how to use the assistant:
     *"Chào bạn! Tôi là trợ lý tài chính Simo. Bạn có thể nói hoặc gõ các khoản thu chi, ví dụ: 'Ăn trưa 35k' hoặc hỏi 'Hôm nay tiêu gì?' nhé!"*
   - No error crash occurs.

---

## 3. Automated Test Command
Run existing and updated AI engine tests:

```bash
cd apps/mobile && flutter test test/ai_engine_test.dart
```
