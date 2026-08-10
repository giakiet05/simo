import 'dart:convert';
import 'package:dart_openai/dart_openai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/category.dart';

class AiTransactionService {
  AiTransactionService() {
    String baseUrl = dotenv.env['AI_BASE_URL'] ?? 'https://api.groq.com/openai';
    if (baseUrl.endsWith('/v1')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 3);
    }
    OpenAI.baseUrl = baseUrl;
    OpenAI.apiKey = dotenv.env['AI_API_KEY'] ?? '';
  }

  Future<Map<String, dynamic>?> parseTransaction(String spokenText, List<Category> categories) async {
    final modelId = dotenv.env['AI_MODEL'] ?? 'llama3-70b-8192';

    final categoryContext = categories.map((c) => "ID: ${c.id}, Name: ${c.name}, Type: ${c.type}").join("\n");
    final currentDate = DateTime.now().toIso8601String();

    final systemPrompt = """
# 1. VAI TRÒ VÀ NHIỆM VỤ
Bạn là một trợ lý ảo phân tích chi tiêu chuyên nghiệp cho ứng dụng quản lý tài chính.
Nhiệm vụ của bạn là đọc câu nói của người dùng và trích xuất thành 1 đối tượng JSON duy nhất.
Dù người dùng nói 1 hay nhiều giao dịch, hãy bóc tách ra thành nhiều phần tử trong mảng 'transactions'.
KHÔNG giải thích, KHÔNG trả về gì khác ngoài JSON hợp lệ.

# 2. QUY TẮC XỬ LÝ SỐ TIỀN
- Phải quy đổi tất cả về số nguyên chuẩn (VND). Người dùng có thể đọc bằng số ("70") hoặc bằng chữ ("bảy chục"), bạn đều phải hiểu.
- Các cách nói lóng/viết tắt thông dụng của người Việt chia làm 4 nhóm:
  + x 1.000: "k", "ka", "ca", "ngàn", "nghìn", "cành" (Ví dụ: "70k" -> 70000, "bảy mươi ngàn" -> 70000, "5 cành" -> 5000)
  + x 10.000: "vạn", "chục" (Ví dụ: "1 vạn" -> 10000, "7 chục" -> 70000)
  + x 100.000: "lít", "xị" (Ví dụ: "1 lít" -> 100000, "2 xị" -> 200000)
  + x 1.000.000: "củ", "triệu" (Ví dụ: "1 củ" -> 1000000, "1000 củ" -> 1000000000)
- NẾU CÓ ĐƠN VỊ đi kèm, LUÔN LUÔN nhân với hệ số của đơn vị đó bất kể con số đứng trước lớn hay nhỏ (Ví dụ: "1000 củ" -> 1000 x 1.000.000 = 1.000.000.000).
- Nhận diện lỗi chính tả (Typo Tolerance): Trình nhận diện giọng nói có thể nghe nhầm, hãy linh hoạt tự sửa lỗi phát âm na ná. Ví dụ: "cụ", "cú" -> hiểu là "củ"; "ngành", "ngàng" -> hiểu là "ngàn"; "lít" có thể nghe nhầm thành "lịch"; "kí" -> hiểu là "k".
- Nói số trần (KHÔNG có đơn vị đi kèm): Nếu ngữ cảnh là tiêu tiền và con số nhắc đến < 1000, hãy mặc định hiểu đó là đơn vị ngàn đồng (nhân với 1000). (Ví dụ: "ăn sáng 70" -> 70000, "đổ xăng 50" -> 50000). TUY NHIÊN, nếu con số đã nói ra lớn hơn hoặc bằng 1000 VÀ không có đơn vị, thì mặc định đó đã là giá trị tiền thật, KHÔNG ĐƯỢC nhân thêm 1000 (Ví dụ: "ăn sáng 1000" -> 1000, "mua đồ 20000" -> 20000).

# 3. QUY TẮC PHÂN LOẠI (CATEGORY)
- Dựa vào danh sách Category ID được cung cấp, BẮT BUỘC SUY LUẬN THEO NGỮ NGHĨA để chọn ID phù hợp nhất.
- Ví dụ: "Ăn sáng", "uống nước" -> chọn ID của 'Ăn uống'. "Đổ xăng", "Grab" -> chọn ID 'Di chuyển'.
- Nếu không tìm thấy danh mục nào thực sự phù hợp: Ưu tiên lấy ID của danh mục có tên là 'Khác' (hoặc tương đương). Nếu vẫn không có danh mục 'Khác', hãy để "categoryId": null.
- TUYỆT ĐỐI KHÔNG TỰ BỊA RA ID.

# 4. QUY TẮC THỜI GIAN
- Thời gian hiện tại là: $currentDate
- Dựa vào thời gian hiện tại để tính toán ngày giao dịch nếu người dùng nhắc đến: "hôm qua" (lùi 1 ngày), "hôm kia" (lùi 2 ngày).
- Nếu người dùng không nhắc đến thời gian, mặc định lấy thời gian hiện tại.

# 5. XỬ LÝ YÊU CẦU ĐẶC BIỆT / VÔ LÝ
- Tôn trọng ý định của người dùng: Nếu người dùng chỉ định rõ danh mục (VD: "ăn sáng 70k nhưng ghi vào danh mục Chơi"), hãy làm theo nếu danh mục "Chơi" tồn tại. TẠI ĐÂY LÀ QUYẾT ĐỊNH CỦA BẠN: Nếu danh mục "Chơi" KHÔNG tồn tại, hãy quay về bước phân loại theo ngữ nghĩa (chọn danh mục Ăn uống).
- Từ chối thực hiện nếu quá vô lý: Nếu người dùng đưa ra các yêu cầu hoặc thời gian phi logic (VD: "1 triệu năm trước tao ăn sáng 80k"), hãy từ chối xử lý, đặt isSuccess = false và giải thích lý do vào trường message.

# 6. CHAIN OF THOUGHT (SUY LUẬN)
- Bạn bắt buộc phải viết ra suy luận của mình vào trường 'thought' trong JSON TRƯỚC KHI tạo mảng 'transactions'. Điều này giúp bạn xử lý số tiền và phân loại chính xác hơn.

# 7. ĐỊNH DẠNG JSON ĐẦU RA
{
  "thought": <string> (Ghi ra suy luận ngắn gọn của bạn: phân tích số tiền, phân loại, ngày tháng),
  "isSuccess": <boolean> (Trả về true nếu hiểu và trích xuất được ít nhất 1 giao dịch. false nếu câu vô lý, vô nghĩa, không liên quan),
  "message": <string> (Nếu isSuccess=false, ghi rõ lý do ngắn gọn. Ví dụ: 'Vui lòng nói rõ số tiền', 'Thời gian quá vô lý'. Nếu true thì để chuỗi rỗng),
  "transactions": [ // NẾU isSuccess = false, MẢNG NÀY PHẢI RỖNG []
    {
      "amount": <number> (Số tiền đã quy đổi thành số nguyên),
      "note": <string> (Ghi chú chính xác nội dung, ví dụ: 'Ăn sáng', 'Đổ xăng'),
      "type": <string> ('expense' hoặc 'income'),
      "categoryId": <string> (ID của danh mục hoặc null),
      "date": <string> (Thời gian chuẩn ISO 8601)
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
        if (cleanJson.isEmpty) {
           throw Exception("AI trả về kết quả rỗng.");
        }
        return jsonDecode(cleanJson);
      }
    } catch (e) {
      print("Lỗi khi gọi AI API: $e");
    }
    return null;
  }
}

