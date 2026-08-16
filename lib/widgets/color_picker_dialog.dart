import 'package:flutter/material.dart';

class ColorPickerDialog extends StatelessWidget {
  final String? selectedColor;

  const ColorPickerDialog({super.key, this.selectedColor});

  static const List<Color> colors = [
    // Reds
    Color(0xFFE57373), Color(0xFFF44336), Color(0xFFD32F2F), Color(0xFFFF5252),
    // Oranges
    Color(0xFFFFB74D), Color(0xFFFF9800), Color(0xFFF57C00), Color(0xFFFF6D00),
    // Yellows
    Color(0xFFFFF176), Color(0xFFFFEB3B), Color(0xFFFBC02D), Color(0xFFFFD600),
    // Greens
    Color(0xFF81C784), Color(0xFF4CAF50), Color(0xFF388E3C), Color(0xFF00C853),
    Color(0xFFAED581), Color(0xFF8BC34A), Color(0xFF558B2F), Color(0xFF64DD17),
    // Teals
    Color(0xFF4DB6AC), Color(0xFF009688), Color(0xFF00796B), Color(0xFF00BFA5),
    // Blues
    Color(0xFF64B5F6), Color(0xFF2196F3), Color(0xFF1976D2), Color(0xFF2962FF),
    Color(0xFF4FC3F7), Color(0xFF03A9F4), Color(0xFF0288D1), Color(0xFF00B0FF),
    Color(0xFF7986CB), Color(0xFF3F51B5), Color(0xFF303F9F), Color(0xFF304FFE),
    // Purples
    Color(0xFFBA68C8), Color(0xFF9C27B0), Color(0xFF7B1FA2), Color(0xFFAA00FF),
    Color(0xFF9575CD), Color(0xFF673AB7), Color(0xFF512DA8), Color(0xFF6200EA),
    // Pinks
    Color(0xFFF06292), Color(0xFFE91E63), Color(0xFFC2185B), Color(0xFFC51162),
    // Browns
    Color(0xFFA1887F), Color(0xFF795548), Color(0xFF5D4037),
    // Grays/Blue-Grays
    Color(0xFF90A4AE), Color(0xFF607D8B), Color(0xFF455A64),
  ];

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Chọn màu'),
      content: SizedBox(
        width: double.maxFinite,
        child: GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 6,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: colors.length,
          itemBuilder: (context, index) {
            final color = colors[index];
            final colorHex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
            final isSelected = selectedColor == colorHex;

            return InkWell(
              onTap: () => Navigator.of(context).pop(colorHex),
              child: Container(
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey[300]!,
                    width: isSelected ? 3 : 1,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 20,
                      )
                    : null,
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
      ],
    );
  }
}
