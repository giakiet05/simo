# Screen Recipes & Boilerplates: SIMO

Tài liệu này cung cấp các đoạn mã nguồn mẫu Flutter (Boilerplates) được thiết kế theo đúng chuẩn **SIMO Design System**. Khi phát triển tính năng mới, bạn chỉ cần sao chép các mẫu này và điền logic nghiệp vụ tương ứng.

---

## 📄 Recipe 1: Màn hình Danh sách Quản lý Chuẩn (Standard CRUD List Screen)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/localization_provider.dart';
import '../providers/settings_provider.dart';
import '../services/currency_service.dart';
import '../widgets/banner_ad_widget.dart';

class StandardListScreen extends ConsumerStatefulWidget {
  const StandardListScreen({super.key});

  @override
  ConsumerState<StandardListScreen> createState() => _StandardListScreenState();
}

class _StandardListScreenState extends ConsumerState<StandardListScreen> {
  String _selectedFilter = 'all';

  void _openCreateModal(BuildContext context) {
    // Mở Form BottomSheet
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(localizationProvider);
    final settings = ref.watch(settingsProvider).value;
    final currency = settings?.currency ?? 'VND';
    final currencySymbol = CurrencyService.getSymbol(currency);
    final numberFormat = NumberFormat('#,###');

    return Scaffold(
      appBar: AppBar(
        title: Text('Tiêu đề màn hình'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Thêm mới',
            onPressed: () => _openCreateModal(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // 1. Thẻ Tổng quan (Hero Overview Card)
                Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Tổng số lượng / giá trị', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              const SizedBox(height: 2),
                              Text('50,000,000 $currencySymbol',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 2. Hàng Chip lọc cuộn ngang (Horizontal Filter Chips)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('Tất cả (5)'),
                        selected: _selectedFilter == 'all',
                        onSelected: (s) => setState(() => _selectedFilter = 'all'),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Đang xử lý (3)'),
                        selected: _selectedFilter == 'active',
                        onSelected: (s) => setState(() => _selectedFilter = 'active'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 3. Danh sách thẻ (Item Cards) hoặc Empty State
                Card(
                  elevation: 0,
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {},
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.teal.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.star, color: Colors.teal, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Tên mục dữ liệu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 2),
                                Text('Chi tiết phụ hoặc ngày tháng', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 4. Banner Ad ở đáy màn hình
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
```

---

## 📝 Recipe 2: Modal BottomSheet Nhập liệu Chuẩn (Form BottomSheet Recipe)

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;
    String clean = newValue.text.replaceAll(',', '');
    final number = int.tryParse(clean);
    if (number == null) return oldValue;
    final formatted = NumberFormat('#,###').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

class StandardFormModal extends StatefulWidget {
  final String currencySymbol;
  final Function(String title, double amount) onSave;

  const StandardFormModal({
    super.key,
    required this.currencySymbol,
    required this.onSave,
  });

  @override
  State<StandardFormModal> createState() => _StandardFormModalState();
}

class _StandardFormModalState extends State<StandardFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final clean = _amountController.text.replaceAll(',', '').trim();
    final amount = double.tryParse(clean) ?? 0.0;

    widget.onSave(_titleController.text.trim(), amount);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        top: 16,
        left: 20,
        right: 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tạo mới thông tin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 16),

              // Title input
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Tên hoặc tiêu đề',
                  prefixIcon: const Icon(Icons.title),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Vui lòng nhập tiêu đề' : null,
              ),
              const SizedBox(height: 16),

              // Currency input
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  CurrencyInputFormatter(),
                ],
                decoration: InputDecoration(
                  labelText: 'Số tiền',
                  suffixText: widget.currencySymbol,
                  prefixIcon: const Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Vui lòng nhập số tiền';
                  final parsed = double.tryParse(val.replaceAll(',', '').trim());
                  if (parsed == null || parsed <= 0) return 'Số tiền phải lớn hơn 0';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Action button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _submit,
                  child: const Text('Lưu thông tin', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
```
