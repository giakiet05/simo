import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/category.dart';
import '../models/wallet.dart';
import '../models/loan_contact.dart';
import '../models/saving_goal.dart';

/// Service interacting with OpenAI API (gpt-5-nano) to parse natural language
/// financial commands, execute multi-action workflows, and answer financial queries.
class AiTransactionService {
  AiTransactionService() {
    _ensureConfigured();
  }

  String _getApiKey() {
    return dotenv.env['AI_API_KEY'] ??
        dotenv.env['OPENAI_API_KEY'] ??
        '';
  }

  void _ensureConfigured() {
    String baseUrl = dotenv.env['AI_BASE_URL'] ??
        dotenv.env['OPENAI_BASE_URL'] ??
        'https://api.openai.com';
    while (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    if (baseUrl.endsWith('/v1')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 3);
    }
    OpenAI.baseUrl = baseUrl;
    OpenAI.requestsTimeOut = const Duration(seconds: 45);
    final key = _getApiKey();
    if (key.isNotEmpty) {
      OpenAI.apiKey = key;
    }
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

  /// Parses user natural speech or typed chat into structured actions and conversational reply.
  /// Handles:
  /// - Standard Transactions (income/expense)
  /// - Wallet Transfers (between wallets)
  /// - Loans & Debts (borrow, lend, repay, collect)
  /// - Saving Goals (deposit, withdraw)
  /// - Contextual Financial Inquiries (balances, daily spending)
  Future<Map<String, dynamic>?> parseUserIntent({
    required String spokenText,
    required List<Category> categories,
    List<Wallet> wallets = const [],
    List<LoanContact> loanContacts = const [],
    List<SavingGoal> savingGoals = const [],
    String? financialSummaryContext,
    List<Map<String, String>> chatHistory = const [],
  }) async {
    _ensureConfigured();

    final apiKey = _getApiKey();
    if (apiKey.isEmpty) {
      debugPrint('AiTransactionService: No API key configured in .env (checked AI_API_KEY, OPENAI_API_KEY)');
      return {
        'thought': 'Missing API key',
        'isSuccess': false,
        'message': 'Chưa cấu hình API Key trong file .env.',
        'responseMessage': 'Bạn chưa cấu hình OpenAI API Key trong file .env. Vui lòng thêm AI_API_KEY=sk-... hoặc OPENAI_API_KEY=sk-... vào file .env nhé!',
        'actions': [],
        'transactions': []
      };
    }

    final modelId = dotenv.env['AI_MODEL'] ?? 'gpt-4o-mini';

    final categoryContext = categories.isEmpty
        ? 'Chua co danh muc'
        : categories.map((c) => 'ID: ${c.id}, Ten: ${c.name}, Loai: ${c.type}').join('\n');

    final walletContext = wallets.isEmpty
        ? 'Chua co vi cu the'
        : wallets.map((w) => 'ID: ${w.id}, Ten: ${w.name}, Loai: ${w.type}, So du: ${w.currentBalance.toInt()} VND').join('\n');

    final loanContactContext = loanContacts.isEmpty
        ? 'Chua co lien he no'
        : loanContacts.map((l) => 'ID: ${l.id}, Ten: ${l.contactName}, Loai: ${l.type}, Du no: ${l.remainingAmount.toInt()} VND').join('\n');

    final savingGoalContext = savingGoals.isEmpty
        ? 'Chua co muc tieu'
        : savingGoals.map((g) => 'ID: ${g.id}, Ten: ${g.name}, Da tich luy: ${g.currentAmount.toInt()}/${g.targetAmount.toInt()} VND').join('\n');

    final summaryContext = financialSummaryContext ?? 'Chua co thong ke chi tiet hom nay.';
    final currentDate = DateTime.now().toIso8601String();

    final systemPrompt = """
# 1. VAI TRO VA NHIEM VU
Ban la tro ly tai chinh thong minh toan dien (AI Financial Agent) cho ung dung quan ly tai chinh ca nhan Simo.
Nhiem vu cua ban:
1. Giao tiep tu nhien, than thien bang tieng Viet giong nhu mot tro ly ca nhan chu dao (xung ho ban - toi hoac than mat, lich su).
2. Phan tich cau noi/chat cua nguoi dung de nhan dien:
   a. Lenh hanh dong (ghi thu chi, chuyen tien, vay no, tiet kiem): trich xuat cac hanh dong vao mang 'actions' va tra loi xac nhan trong 'responseMessage'.
   b. Cau hoi/Thac mac tai chinh (vi du: "hom nay tieu bao nhieu?", "vi Techcom con bao nhieu?"): su dung Du lieu ngu canh duoc cung cap de giai dap chinh xac trong 'responseMessage', mang 'actions' de rong [].
   c. Tro chuyen/Chao hoi xa giao: phan hoi lich thiep va huong dan nguoi dung ghi chep tai chinh, 'actions' de rong [].
3. CHU Y: Luon tra ve DUY NHAT 1 doi tuong JSON hop le, KHONG giai thich them ngoai JSON, KHONG boc markdown.

# 2. CAC LOAI HANH DONG (actionType trong actions)
1) "transaction" - Thu chi thong thuong:
   - Thuoc tinh: "amount", "type" ('expense' hoac 'income'), "note", "categoryId", "walletId", "date".
2) "transfer" - Chuyen tien giua 2 vi:
   - Thuoc tinh: "amount", "sourceWalletId", "destinationWalletId", "fee", "note", "date".
3) "loan_create" - Tao khoan vay hoac cho vay moi:
   - Thuoc tinh: "amount", "loanType" ('lent' hoac 'borrowed'), "contactName", "contactId", "walletId", "note", "date".
4) "loan_repay" - Tra no hoac Thu hoi no:
   - Thuoc tinh: "amount", "repayType" ('collect' hoac 'repay'), "contactName", "contactId", "walletId", "note", "date".
5) "goal_deposit" - Gop tien / Bo heo vao muc tieu tiet kiem:
   - Thuoc tinh: "amount", "goalId", "goalName", "walletId", "note", "date".
6) "goal_withdraw" - Rut tien tu muc tieu tiet kiem:
   - Thuoc tinh: "amount", "goalId", "goalName", "walletId", "note", "date".

# 3. QUY TAC TIEN TE VIET NAM
- Quy doi ve so nguyen VND:
  + x 1.000: "k", "ka", "ca", "ngan", "nghin", "canh" (70k -> 70000, 5 canh -> 5000)
  + x 10.000: "van", "chuc" (1 van -> 10000, 7 chuc -> 70000)
  + x 100.000: "lit", "xi" (1 lit -> 100000, 2 xi -> 200000)
  + x 1.000.000: "cu", "trieu" (1 cu -> 1000000, 2 trieu -> 2000000)
- So tran khong don vi: Neu < 1000 mac dinh nhan 1000 (vi du: "an sang 45" -> 45000). Neu >= 1000 giu nguyen.

# 4. QUY TAC ANH XA THUC THE
- Danh muc: Khop categoryId phu hop nhat. Neu khong tim thay, de null.
- Vi tien: Khop walletId theo ten vi (tien mat, momo, techcom, vcb...). Neu khong nhac den vi, de null (he thong dung vi mac dinh).
- Lien he no: Khop contactId neu co trong danh sach, neu nguoi moi thi contactId: null va dien contactName.
- Muc tieu: Khop goalId theo ten muc tieu. Neu moi thi goalId: null va dien goalName.
- TUYET DOI KHONG TU BIA RA ID KHONG CO TRONG NGU CANH.

# 5. QUY TAC THOI GIAN
- Thoi gian hien tai: $currentDate
- Tinh lui ngay neu co: "hom qua" (-1 ngay), "hom kia" (-2 ngay), "tuan truoc" (-7 ngay).

# 6. DINH DANG JSON DAU RA (BAT BUOC)
{
  "isSuccess": <boolean> (true neu hieu va xu ly duoc, false neu cau noi hoan toan vo nghia),
  "responseMessage": <string> (Cau tra loi hoi thoai ngan gon bang tieng Viet xac nhan hanh dong hoac giai dap thac mac),
  "message": <string> (Thong bao neu isSuccess=false),
  "actions": [
    {
      "actionType": "transaction" | "transfer" | "loan_create" | "loan_repay" | "goal_deposit" | "goal_withdraw",
      "amount": <number>,
      "date": <string> (ISO 8601),
      "note": <string>,
      "type": "expense" | "income",
      "categoryId": <string | null>,
      "walletId": <string | null>,
      "sourceWalletId": <string | null>,
      "destinationWalletId": <string | null>,
      "fee": <number>,
      "loanType": "lent" | "borrowed" | null,
      "repayType": "collect" | "repay" | null,
      "contactName": <string | null>,
      "contactId": <string | null>,
      "goalId": <string | null>,
      "goalName": <string | null>
    }
  ],
  "thought": <string> (Giai thich ngan gon duoi 15 tu)
}

---
DU LIEU NGU CANH NGUOI DUNG:
[Danh muc (Categories)]:
$categoryContext

[Vi tien (Wallets)]:
$walletContext

[Lien he no (Loan Contacts)]:
$loanContactContext

[Muc tieu tiet kiem (Saving Goals)]:
$savingGoalContext

[Tong quan hom nay (Today Summary)]:
$summaryContext
""";

    try {
      final messagesList = <OpenAIChatCompletionChoiceMessageModel>[
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.system,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(systemPrompt)],
        ),
      ];

      // Append recent conversational context
      for (final turn in chatHistory) {
        final role = turn['role'] == 'user'
            ? OpenAIChatMessageRole.user
            : OpenAIChatMessageRole.assistant;
        final content = turn['content'] ?? '';
        if (content.isNotEmpty) {
          messagesList.add(
            OpenAIChatCompletionChoiceMessageModel(
              role: role,
              content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(content)],
            ),
          );
        }
      }

      // Append the current turn
      messagesList.add(
        OpenAIChatCompletionChoiceMessageModel(
          role: OpenAIChatMessageRole.user,
          content: [OpenAIChatCompletionChoiceMessageContentItemModel.text(spokenText)],
        ),
      );

      final chatCompletion = await OpenAI.instance.chat.create(
        model: modelId,
        messages: messagesList,
        responseFormat: const {"type": "json_object"},
      );

      final contentItems = chatCompletion.choices.first.message.content;
      String? responseText;
      if (contentItems != null && contentItems.isNotEmpty) {
        responseText = contentItems.map((c) => c.text ?? '').join();
      }

      if (responseText != null && responseText.isNotEmpty) {
        var cleanJson = responseText.replaceAll('```json', '').replaceAll('```', '').trim();
        final startIndex = cleanJson.indexOf('{');
        final endIndex = cleanJson.lastIndexOf('}');
        if (startIndex != -1 && endIndex != -1 && startIndex < endIndex) {
          cleanJson = cleanJson.substring(startIndex, endIndex + 1);
        }

        Map<String, dynamic> parsed;
        try {
          parsed = jsonDecode(cleanJson) as Map<String, dynamic>;
        } catch (e) {
          debugPrint('AiTransactionService: Non-JSON response received, fallback gracefully: $responseText');
          parsed = {
            'isSuccess': true,
            'responseMessage': responseText,
            'thought': 'Raw text fallback',
            'actions': [],
            'transactions': [],
          };
        }

        // Backward compatibility fallback: ensure 'transactions' array exists
        if (!parsed.containsKey('transactions') && parsed.containsKey('actions')) {
          final actions = parsed['actions'] as List<dynamic>? ?? [];
          parsed['transactions'] = actions
              .where((a) => a['actionType'] == 'transaction')
              .toList();
        }

        // Ensure default response message if omitted by model
        if (!parsed.containsKey('responseMessage') || parsed['responseMessage'] == null) {
          final actions = parsed['actions'] as List<dynamic>? ?? [];
          if (actions.isNotEmpty) {
            parsed['responseMessage'] = 'Tôi đã ghi nhận xong các giao dịch của bạn!';
          } else {
            parsed['responseMessage'] = parsed['message'] ?? 'Tôi đã nhận được thông tin từ bạn!';
          }
        }

        return parsed;
      }
    } on TimeoutException catch (e) {
      debugPrint('AiTransactionService error: Request timed out: $e');
      return {
        'thought': 'Request timed out',
        'isSuccess': false,
        'message': 'Yêu cầu kết nối AI bị quá thời gian chờ (Timeout).',
        'responseMessage': 'Kết nối tới OpenAI bị quá thời gian chờ (Timeout). Bạn vui lòng kiểm tra lại kết nối mạng hoặc thử lại nhé!',
        'actions': [],
        'transactions': []
      };
    } catch (e) {
      debugPrint('AiTransactionService error: $e');
      final errorStr = e.toString();
      if (errorStr.contains('401') || errorStr.contains('API key')) {
        return {
          'thought': 'Invalid or Missing API Key',
          'isSuccess': false,
          'message': 'API Key không hợp lệ hoặc chưa được cung cấp (Lỗi 401).',
          'responseMessage': 'OpenAI API Key không hợp lệ hoặc tài khoản chưa có quyền truy cập model (Lỗi 401). Bạn vui lòng kiểm tra biến AI_API_KEY hoặc OPENAI_API_KEY trong file .env nhé!',
          'actions': [],
          'transactions': []
        };
      }
    }
    return null;
  }
}
