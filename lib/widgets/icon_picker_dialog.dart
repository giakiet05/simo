import 'package:flutter/material.dart';
import '../utils/icon_data.dart';

class IconPickerDialog extends StatefulWidget {
  final String? selectedIcon;
  final String categoryType; // 'income' or 'expense'

  const IconPickerDialog({
    super.key,
    this.selectedIcon,
    required this.categoryType,
  });

  @override
  State<IconPickerDialog> createState() => _IconPickerDialogState();
}

class _IconPickerDialogState extends State<IconPickerDialog> {
  String _searchQuery = '';
  List<String> _filteredIcons = [];

  @override
  void initState() {
    super.initState();
    _updateFilteredIcons();
  }

  void _updateFilteredIcons() {
    setState(() {
      if (_searchQuery.isEmpty) {
        // Show all icons
        _filteredIcons = CategoryIconData.iconMap.keys.toList();
      } else {
        _filteredIcons = CategoryIconData.searchIcons(_searchQuery);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: double.maxFinite,
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Title
            const Text(
              'Chọn icon',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Search bar
            TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm icon...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onChanged: (value) {
                _searchQuery = value;
                _updateFilteredIcons();
              },
            ),
            const SizedBox(height: 16),

            // Icon grid
            Expanded(
              child: _filteredIcons.isEmpty
                  ? const Center(child: Text('Không tìm thấy icon'))
                  : GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: _filteredIcons.length,
                      itemBuilder: (context, index) {
                        final iconName = _filteredIcons[index];
                        final iconData = CategoryIconData.getIcon(iconName);
                        final isSelected = widget.selectedIcon == iconName;

                        return InkWell(
                          onTap: () => Navigator.of(context).pop(iconName),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Colors.grey[300]!,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Icon(
                              iconData,
                              size: 32,
                              color: Colors.black87,
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // Actions
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Hủy'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
