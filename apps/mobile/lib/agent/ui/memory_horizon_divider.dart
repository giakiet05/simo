import 'package:flutter/material.dart';

/// Visual indicator widget displayed in chat to show where the AI's 10-turn working memory begins.
class MemoryHorizonDivider extends StatelessWidget {
  const MemoryHorizonDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              thickness: 1,
              endIndent: 10,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.psychology,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  'AI ghi nhớ từ đây (10 tin gần nhất)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Divider(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
              thickness: 1,
              indent: 10,
            ),
          ),
        ],
      ),
    );
  }
}
