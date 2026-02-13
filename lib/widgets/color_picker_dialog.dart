import 'package:flutter/material.dart';

class ColorPickerDialog extends StatelessWidget {
  final String? selectedColor;

  const ColorPickerDialog({super.key, this.selectedColor});

  static const List<Color> colors = [
    // Reds
    Color(0xFFE57373), // Light Red
    Color(0xFFF44336), // Red
    Color(0xFFD32F2F), // Dark Red

    // Oranges
    Color(0xFFFFB74D), // Light Orange
    Color(0xFFFF9800), // Orange
    Color(0xFFF57C00), // Dark Orange

    // Yellows
    Color(0xFFFFF176), // Light Yellow
    Color(0xFFFFEB3B), // Yellow
    Color(0xFFFBC02D), // Dark Yellow

    // Greens
    Color(0xFF81C784), // Light Green
    Color(0xFF4CAF50), // Green
    Color(0xFF388E3C), // Dark Green

    // Teals
    Color(0xFF4DB6AC), // Light Teal
    Color(0xFF009688), // Teal
    Color(0xFF00796B), // Dark Teal

    // Blues
    Color(0xFF64B5F6), // Light Blue
    Color(0xFF2196F3), // Blue
    Color(0xFF1976D2), // Dark Blue

    // Purples
    Color(0xFFBA68C8), // Light Purple
    Color(0xFF9C27B0), // Purple
    Color(0xFF7B1FA2), // Dark Purple

    // Pinks
    Color(0xFFF06292), // Light Pink
    Color(0xFFE91E63), // Pink
    Color(0xFFC2185B), // Dark Pink

    // Grays
    Color(0xFF90A4AE), // Light Gray
    Color(0xFF607D8B), // Gray
    Color(0xFF455A64), // Dark Gray
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
