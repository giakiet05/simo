import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/category.dart';
import '../models/wallet.dart';
import '../models/loan_contact.dart';
import '../models/saving_goal.dart';

class AiTransactionService {
  AiTransactionService() {
    String baseUrl = dotenv.env['AI_BASE_URL'] ?? 'https://api.groq.com/openai';
    if (baseUrl.endsWith('/v1')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 3);
    }
    OpenAI.baseUrl = baseUrl;
    OpenAI.apiKey = dotenv.env['AI_API_KEY'] ?? '';
  }

  /// Backward-compatible method for parsing basic transactions.
  Future<Map<String, dynamic>?> parseTransaction(
    String spokenText,
    List<Category> categories, {
    List<Wallet> wallets = const [],
    List<LoanContact> loanContacts = const [],
    List<SavingGoal> savingGoals = const [],
  }) async {
    return parseUserIntent(
      spokenText: spokenText,
      categories: categories,
      wallets: wallets,
      loanContacts: loanContacts,
      savingGoals: savingGoals,
    );
  }

  /// Parses user natural speech into structured actions covering:
  /// - Standard Transactions (income/expense)
  /// - Wallet Transfers (between wallets)
  /// - Loans & Debts (borrow, lend, repay, collect)
  /// - Saving Goals (deposit, withdraw)
  Future<Map<String, dynamic>?> parseUserIntent({
    required String spokenText,
    required List<Category> categories,
    List<Wallet> wallets = const [],
    List<LoanContact> loanContacts = const [],
    List<SavingGoal> savingGoals = const [],
  }) async {
    final modelId = dotenv.env['AI_MODEL'] ?? 'llama-3.3-70b-versatile';

    final categoryContext = categories.isEmpty
        ? 'Chưa có danh mục'
        : categories.map((c) => 'ID: ${c.id}, Tên: ${c.name}, Loại: ${c.type}').join('\n');

    final walletContext = wallets.isEmpty
        ? 'Chưa có ví cụ thể'
        : wallets.map((w) => 'ID: ${w.id}, Tên: ${w.name}, Loại: ${w.type}').join('\n');

    final loanContactContext = loanContacts.isEmpty
        ? 'Chưa có liên hệ nợ'
        : loanContacts.map((l) => 'ID: ${l.id}, Tên: ${l.contactName}, Loại: ${l.type}, Dư nợ: ${l.remainingAmount}').join('\n');

    final savingGoalContext = savingGoals.isEmpty
        ? 'Chưa có mục tiêu'
        : savingGoals.map((g) => 'ID: ${g.id}, Tên: ${g.name}, Đã tích lũy: ${g.currentAmount}/${g.targetAmount}').join('\n');

    final currentDate = DateTime.now().toIso8601String();

    final systemPrompt = """
# 1. VAI TRÒ VÀ NHIỆM VỤ
Bạn là trợ lý tài chính thông minh toàn diện cho ứng dụng quản lý tài chính cá nhân.
Nhiệm vụ của bạn là phân tích câu nói của người dùng và trích xuất thành 1 đối tượng JSON duy nhất.
Người dùng có thể yêu cầu 1 hoặc NHIỀU hành động trong cùng một câu nói. Hãy phân tách chúng thành các phần tử trong mảng 'actions'.
KHÔNG giải thích, KHÔNG markdown, CHỈ trả về JSON hợp lệ.

# 2. CÁC LOẠI HÀNH ĐỘNG (actionType)
Phân loại chính xác từng hành động của người dùng vào 1 trong các loại sau:

1) "transaction" - Thu chi thông thường:
   - "Ăn sáng 50k", "Mua sắm 200k thẻ Techcombank", "Lương về ví MoMo 15 củ".
   - Thuộc tính: "amount", "type" ('expense' hoặc 'income'), "note", "categoryId", "walletId", "date".

2) "transfer" - Chuyển tiền qua lại giữa 2 ví:
   - "Chuyển 2 triệu từ Techcombank sang ví MoMo", "Rút 500k từ VCB về Tiền mặt".
   - Thuộc tính: "amount", "sourceWalletId", "destinationWalletId", "fee", "note", "date".

3) "loan_create" - Tạo khoản vay hoặc cho vay mới:
   - "Cho Tuấn mượn 500k", "Cho anh Ba vay 2 triệu", "Vay mẹ 10 triệu tiêu dùng", "Vay VPBank 20 triệu".
   - Thuộc tính: "amount", "loanType" ('lent' nếu mình cho người khác vay/mượn; 'borrowed' nếu mình đi vay/mượn tiền từ người khác), "contactName" (tên người/tổ chức), "contactId" (nếu có trong danh bạ), "walletId", "note", "date".

4) "loan_repay" - Trả nợ hoặc Thu hồi nợ:
   - "Tuấn trả 200k nợ", "Đã trả nợ mẹ 2 triệu", "Thu nợ anh Ba 500k".
   - Thuộc tính: "amount", "repayType" ('collect' nếu người ta trả nợ cho mình; 'repay' nếu mình trả nợ cho người khác), "contactName", "contactId", "walletId", "note", "date".

5) "goal_deposit" - Góp tiền / Bỏ heo vào mục tiêu tiết kiệm:
   - "Bỏ heo 500k vào mục tiêu Mua xe", "Nạp 1 củ vô quỹ Du lịch", "Tiết kiệm 2 triệu mua iPhone".
   - Thuộc tính: "amount", "goalId" (nếu khớp tên trong danh sách mục tiêu), "goalName", "walletId", "note", "date".

6) "goal_withdraw" - Rút tiền từ mục tiêu tiết kiệm:
   - "Rút 1 triệu từ quỹ Du lịch", "Lấy 500k từ heo Mua xe ra tiêu".
   - Thuộc tính: "amount", "goalId", "goalName", "walletId", "note", "date".

# 3. QUY TẮC XỬ LÝ SỐ TIỀN
- Phải quy đổi tất cả về số nguyên chuẩn (VND). Người dùng có thể đọc bằng số hoặc chữ.
- Các cách nói lóng/viết tắt thông dụng của người Việt:
  + x 1.000: "k", "ka", "ca", "ngàn", "nghìn", "cành" (Ví dụ: "70k" -> 70000, "bảy mươi ngàn" -> 70000, "5 cành" -> 5000)
  + x 10.000: "vạn", "chục" (Ví dụ: "1 vạn" -> 10000, "7 chục" -> 70000)
  + x 100.000: "lít", "xị" (Ví dụ: "1 lít" -> 100000, "2 xị" -> 200000)
  + x 1.000.000: "củ", "triệu" (Ví dụ: "1 củ" -> 1000000, "1000 củ" -> 1000000000)
- NẾU CÓ ĐƠN VỊ đi kèm, LUÔN LUÔN nhân với hệ số của đơn vị đó (Ví dụ: "1000 củ" -> 1.000.000.000).
- Nhận diện lỗi chính tả/nghe nhầm: "cụ", "cú" -> hiểu là "củ"; "ngành", "ngàng" -> "ngàn"; "lít" -> nghe nhầm thành "lịch"; "kí" -> "k".
- Nói số trần (KHÔNG có đơn vị): Nếu con số nhắc đến < 1000, mặc định nhân với 1000 (Ví dụ: "ăn sáng 70" -> 70000). Nếu >= 1000 và không có đơn vị, giữ nguyên (Ví dụ: "mua đồ 20000" -> 20000).

# 4. QUY TẮC ÁNH XẠ THỰC THỂ (MATCHING RULES)
- Danh mục (category): Tìm ID khớp nhất theo ngữ nghĩa. Nếu không có danh mục phù hợp, gán null hoặc ID 'Khác'.
- Ví tiền (walletId, sourceWalletId, destinationWalletId): Tìm ID trong danh sách ví có tên khớp hoặc tương đương (VD: "Techcom", "TCB" -> ví Techcombank; "tiền mặt", "bóp" -> ví Tiền mặt; "momo" -> ví MoMo). Nếu không nhắc đến ví, để null (hệ thống sẽ tự gán ví mặc định).
- Người vay/cho vay (contactId): Nếu tên người dùng nhắc đến tương ứng với người đã có trong Danh sách Liên hệ nợ, hãy gán đúng ID của họ. Nếu là người mới, để contactId: null và điền contactName.
- Mục tiêu tiết kiệm (goalId): Khớp ID nếu tên mục tiêu người dùng nói tương đồng với mục tiêu đã có. Nếu không khớp, để goalId: null và điền goalName.
- TUYỆT ĐỐI KHÔNG TỰ BỊA RA ID KHÔNG TỒN TẠI.

# 5. QUY TẮC THỜI GIAN
- Thời gian hiện tại là: $currentDate
- Tự động tính lùi ngày nếu nhắc: "hôm qua" (lùi 1 ngày), "hôm kia" (lùi 2 ngày), "tuần trước" (lùi 7 ngày). Nếu không nói thời gian, dùng thời gian hiện tại.

# 6. ĐỊNH DẠNG JSON ĐẦU RA
{
  "thought": <string> (Ghi rõ suy luận bóc tách từng hành động, số tiền, ví, đối tượng),
  "isSuccess": <boolean> (true nếu hiểu và trích xuất được ít nhất 1 hành động hợp lệ, false nếu vô nghĩa/quá vô lý),
  "message": <string> (Thông báo lỗi ngắn gọn nếu isSuccess=false),
  "actions": [
    {
      "actionType": "transaction" | "transfer" | "loan_create" | "loan_repay" | "goal_deposit" | "goal_withdraw",
      "amount": <number>,
      "date": <string> (ISO 8601),
      "note": <string>,
      "type": "expense" | "income" (chỉ cho transaction),
      "categoryId": <string | null>,
      "walletId": <string | null>,
      "sourceWalletId": <string | null> (chỉ cho transfer),
      "destinationWalletId": <string | null> (chỉ cho transfer),
      "fee": <number> (mặc định 0),
      "loanType": "lent" | "borrowed" (chỉ cho loan_create),
      "repayType": "collect" | "repay" (chỉ cho loan_repay),
      "contactName": <string | null>,
      "contactId": <string | null>,
      "goalId": <string | null>,
      "goalName": <string | null>
    }
  ],
  "transactions": [
    // Tự động sao chép các action có actionType=="transaction" vào đây để tương thích ngược:
    // { "amount": <number>, "note": <string>, "type": <string>, "categoryId": <string | null>, "walletId": <string | null>, "date": <string> }
  ]
}

---
NGỮ CẢNH DỮ LIỆU CỦA NGƯỜI DÙNG:
[Danh mục (Categories)]:
$categoryContext

[Ví tiền (Wallets)]:
$walletContext

[Liên hệ nợ (Loan Contacts)]:
$loanContactContext

[Mục tiêu tiết kiệm (Saving Goals)]:
$savingGoalContext
""";

    try {
      final chatCompletion = await OpenAI.instance.chat.create(
        model: modelId,
        messages: [
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.system,
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt)],
          ),
          OpenAIChatCompletionChoiceMessageModel(
            role: OpenAIChatMessageRole.user,
            content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(spokenText)],
          ),
        ],
        temperature: 0.1,
      );

      final responseText = chatCompletion.choices.first.message.content?.first.text;
      if (responseText != null) {
        var cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
        final startIndex = cleanJson.indexOf('{');
        final endIndex = cleanJson.lastIndexOf('}');
        if (startIndex != -1 && endIndex != -1 && startIndex < endIndex) {
          cleanJson = cleanJson.substring(startIndex, endIndex + 1);
        }

        if (cleanJson.isEmpty) {
          throw Exception('AI returned empty JSON');
        }

        final parsed = jsonDecode(cleanJson) as Map<String, dynamic>;

        // Backward compatibility fallback: ensure 'transactions' array exists
        if (!parsed.containsKey('transactions') && parsed.containsKey('actions')) {
          final actions = parsed['actions'] as List<dynamic>? ?? [];
          parsed['transactions'] = actions
              .where((a) => a['actionType'] == 'transaction')
              .toList();
        }

        return parsed;
      }
    } catch (e) {
      // Internal logging without exposing secrets
      debugPrint('AiTransactionService error: $e');
    }
    return null;
  }
}


