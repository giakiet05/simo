import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:simo/models/ai_message.dart';
import 'package:simo/widgets/ai/ai_message_bubble.dart';

void main() {
  group('AiMessageBubble Markdown Rendering Widget Tests', () {
    testWidgets('renders assistant message using MarkdownBody and formats bold text', (tester) async {
      final message = AiMessage.assistant(
        content: 'Đã tạo ví **Lỏ** thành công, số dư ban đầu **800.000đ**.',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiMessageBubble(message: message),
          ),
        ),
      );

      // Verify MarkdownBody is rendered
      expect(find.byType(MarkdownBody), findsOneWidget);

      // Verify RichText within MarkdownBody contains bold text
      final richTexts = tester.widgetList<RichText>(
        find.descendant(
          of: find.byType(MarkdownBody),
          matching: find.byType(RichText),
        ),
      );
      expect(richTexts, isNotEmpty);

      // Check that the text tree contains bold textSpan
      bool hasBoldSpan = false;
      for (final rt in richTexts) {
        rt.text.visitChildren((span) {
          if (span is TextSpan && span.style?.fontWeight == FontWeight.bold) {
            hasBoldSpan = true;
          }
          return true;
        });
      }
      expect(hasBoldSpan, isTrue, reason: 'Markdown should render bold text span');
    });

    testWidgets('renders user message using regular text widget', (tester) async {
      final message = AiMessage.user('Số dư tăng lên 800000');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiMessageBubble(message: message),
          ),
        ),
      );

      expect(find.byType(MarkdownBody), findsNothing);
      expect(find.text('Số dư tăng lên 800000'), findsOneWidget);
    });

    testWidgets('renders thinking indicator when message is in thinking status', (tester) async {
      final message = AiMessage.assistantThinking();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AiMessageBubble(message: message),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('AI đang phân tích & xử lý...'), findsOneWidget);
    });
  });
}
