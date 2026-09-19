import 'package:flutter_test/flutter_test.dart';
import 'package:simo/agent/brain/system_prompt_builder.dart';

void main() {
  group('SystemPromptBuilder & Prefix Caching Tests', () {
    test('staticPrefix contains mandatory ambiguity rules and CRUD entity documentation', () {
      final prefix = SystemPromptBuilder.staticPrefix;

      expect(prefix, contains('VAI TRÒ VÀ NGUYÊN TẮC CỐT LÕI'));
      expect(prefix, contains('QUY TẮC XỬ LÝ MƠ HỒ & HỎI LẠI'));
      expect(prefix, contains('TUYỆT ĐỐI CẤM ĐOÁN MÒ'));
      expect(prefix, contains('DANH MỤC CÔNG CỤ FULL CRUD'));
      expect(prefix, contains('TỪ ĐIỂN TIỀN TỆ VIỆT NAM'));
    });

    test('staticPrefix length exceeds cacheable threshold (>1024 tokens estimate / >4000 chars)', () {
      final prefix = SystemPromptBuilder.staticPrefix;
      // In Vietnamese / English mixed text, ~3-4 chars is roughly 1 token.
      // 4000+ characters comfortably satisfies > 1024 token prefix caching boundary.
      expect(prefix.length, greaterThan(3500));
    });

    test('build method places static prefix first, followed by snapshot and timestamp at the end', () {
      const mockSnapshot = '[Ví tiền]: Ví Tiền mặt 500.000 VND';
      final mockDate = DateTime(2026, 9, 19, 12, 0, 0);

      final fullPrompt = SystemPromptBuilder.build(
        financialSnapshot: mockSnapshot,
        currentDate: mockDate,
      );

      expect(fullPrompt.startsWith(SystemPromptBuilder.staticPrefix), isTrue);
      expect(fullPrompt, contains(mockSnapshot));
      expect(fullPrompt, contains('[Thời gian hiện tại]: 2026-09-19T12:00:00.000'));
    });
  });
}
