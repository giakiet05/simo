import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/category.dart';

class AiTransactionService {
  AiTransactionService() {
    OpenAI.baseUrl = dotenv.env['AI_BASE_URL'] ?? 'https://api.groq.com/openai/v1';
    OpenAI.apiKey = dotenv.env['AI_API_KEY'] ?? '';
  }

  Future<Map<String, dynamic>?> parseTransaction(String spokenText, List<Category> categories) async {
    final modelId = dotenv.env['AI_MODEL'] ?? 'llama3-70b-8192';

    // Tạo context cho danh mục
    final categoryContext = categories.map((c) => "ID: ${c.id}, Name: ${c.name}, Type: ${c.type}").join("\n");
    final currentDate = DateTime.now().toIso8601String();

    final systemPrompt = """
Bạn là một trợ lý ảo phân tích chi tiêu chuyên nghiệp cho ứng dụng quản lý tài chính.
Nhiệm vụ của bạn là đọc câu nói của người dùng và trích xuất thành 1 đối tượng JSON duy nhất có chứa một mảng 'transactions'.
Dù người dùng nói 1 hay nhiều giao dịch, hãy bóc tách ra thành nhiều phần tử trong mảng.
KHÔNG giải thích, KHÔNG trả về gì khác ngoài JSON hợp lệ.

Định dạng JSON cần trả về:
{
  "transactions": [
    {
      "amount": <number> (Phải quy đổi về một số nguyên chuẩn. Chú ý các cách nói thông dụng của người Việt: VD 'bảy mươi', 'bảy chục', '70', '70k', 'bảy mươi ngàn', 'bảy mươi nghìn', '70000' thì đều phải quy về thành 70000. '1 triệu' hoặc '1 củ' -> 1000000. Lưu ý nếu người dùng nói số trần như '70' trong ngữ cảnh tiền tệ thì hiểu là 70 ngàn -> 70000),
      "note": <string> (Ghi chú chính xác hành động người dùng nói, ví dụ: 'Ăn sáng', 'Đổ xăng', 'Đi Grab', 'Tiền điện'),
      "type": <string> ('expense' nếu là chi tiêu, 'income' nếu là thu nhập),
      "categoryId": <string> (BẮT BUỘC SUY LUẬN THEO NGỮ NGHĨA để chọn ID danh mục phù hợp nhất. VD: 'Ăn sáng' -> chọn ID của 'Ăn uống', 'Grab' -> chọn ID của 'Di chuyển'. Trả về chính xác chuỗi ID của danh mục đó. Nếu không tìm thấy danh mục nào phù hợp, HÃY ƯU TIÊN lấy ID của danh mục có tên là 'Khác' (nếu có). Chỉ khi nào danh sách rỗng hoặc không có cả danh mục 'Khác' thì mới trả về null. TUYỆT ĐỐI KHÔNG TỰ BỊA RA ID),
      "date": <string> (Thời gian giao dịch theo chuẩn ISO 8601. Dựa vào thời gian hiện tại là $currentDate, nếu người dùng nói 'hôm qua' thì tính lùi 1 ngày)
    }
  ]
}

Danh sách Category hiện có:
$categoryContext
""";

    print("========== AI PROMPT ==========");
    for (var line in systemPrompt.split('\n')) {
      print(line);
    }
    print("===============================");

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
        // Cắt lấy đúng phần JSON nếu AI có lỡ nói nhảm
        final startIndex = cleanJson.indexOf('{');
        final endIndex = cleanJson.lastIndexOf('}');
        if (startIndex != -1 && endIndex != -1 && startIndex < endIndex) {
          cleanJson = cleanJson.substring(startIndex, endIndex + 1);
        }
        
        print("========== AI JSON RESULT ==========");
        for (var line in cleanJson.split('\n')) {
          print(line);
        }
        print("====================================");
        return jsonDecode(cleanJson);
      }
    } catch (e) {
      print("Lỗi khi gọi AI API: $e");
    }
    return null;
  }
}
