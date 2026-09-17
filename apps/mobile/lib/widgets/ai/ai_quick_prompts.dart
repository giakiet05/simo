import 'package:flutter/material.dart';

/// Widget rendering quick suggestion chips for fast user interaction with the AI Assistant.
class AiQuickPrompts extends StatelessWidget {
  final ValueChanged<String> onSelectPrompt;

  const AiQuickPrompts({
    super.key,
    required this.onSelectPrompt,
  });

  static const List<String> defaultPrompts = [
    'Ăn trưa 45k tiền mặt',
    'Cà phê 35k ví MoMo',
    'Hôm nay tôi đã tiêu bao nhiêu?',
    'Đổ xăng năm chục',
    'Chuyển 500k từ Techcom sang MoMo',
    'Cho bạn mượn 200k',
    'Bỏ heo 500k vào mục tiêu mua xe',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Gợi ý nhanh cho bạn:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: defaultPrompts.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final prompt = defaultPrompts[index];
              return ActionChip(
                label: Text(
                  prompt,
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: Theme.of(context).dividerColor.withValues(alpha: 0.3),
                  ),
                ),
                onPressed: () => onSelectPrompt(prompt),
              );
            },
          ),
        ),
      ],
    );
  }
}
