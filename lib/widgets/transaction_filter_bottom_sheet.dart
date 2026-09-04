import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/category.dart';
import '../models/transaction.dart';
import '../models/transaction_filter_criteria.dart';
import '../models/wallet.dart';
import '../utils/icon_data.dart';
import 'month_year_picker_modal.dart';

class TransactionFilterBottomSheet extends StatefulWidget {
  final TransactionFilterCriteria initialCriteria;
  final List<Wallet> wallets;
  final List<Category> categories;
  final dynamic l10n;
  final List<Transaction> allTransactions;

  const TransactionFilterBottomSheet({
    super.key,
    required this.initialCriteria,
    required this.wallets,
    required this.categories,
    required this.l10n,
    this.allTransactions = const [],
  });

  static Future<TransactionFilterCriteria?> show({
    required BuildContext context,
    required TransactionFilterCriteria initialCriteria,
    required List<Wallet> wallets,
    required List<Category> categories,
    required dynamic l10n,
    List<Transaction> allTransactions = const [],
  }) {
    return showModalBottomSheet<TransactionFilterCriteria>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => TransactionFilterBottomSheet(
        initialCriteria: initialCriteria,
        wallets: wallets,
        categories: categories,
        l10n: l10n,
        allTransactions: allTransactions,
      ),
    );
  }

  @override
  State<TransactionFilterBottomSheet> createState() => _TransactionFilterBottomSheetState();
}

class _TransactionFilterBottomSheetState extends State<TransactionFilterBottomSheet> {
  late TransactionFilterCriteria _criteria;
  late TextEditingController _minAmountController;
  late TextEditingController _maxAmountController;

  @override
  void initState() {
    super.initState();
    _criteria = widget.initialCriteria;
    _minAmountController = TextEditingController(
      text: _criteria.minAmount != null ? _criteria.minAmount!.toInt().toString() : '',
    );
    _maxAmountController = TextEditingController(
      text: _criteria.maxAmount != null ? _criteria.maxAmount!.toInt().toString() : '',
    );
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _pickCustomMonth() {
    final now = DateTime.now();
    final monthRange = MonthRange.fromTransactions(widget.allTransactions);
    final initialMonth = _criteria.customMonth ?? now;

    showMonthYearPickerModal(
      context,
      widget.l10n,
      currentYear: initialMonth.year,
      currentMonth: initialMonth.month,
      startYear: monthRange.startYear,
      startMonth: monthRange.startMonth,
      endYear: monthRange.endYear,
      endMonth: monthRange.endMonth,
      onSelected: (year, month) {
        setState(() {
          _criteria = _criteria.copyWith(
            timeMode: TimeFilterMode.customMonth,
            customMonth: DateTime(year, month, 1),
            clearStartDate: true,
            clearEndDate: true,
          );
        });
      },
    );
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final initialRange = (_criteria.startDate != null && _criteria.endDate != null)
        ? DateTimeRange(start: _criteria.startDate!, end: _criteria.endDate!)
        : DateTimeRange(
            start: now.subtract(const Duration(days: 7)),
            end: now,
          );

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: initialRange,
    );

    if (picked != null) {
      setState(() {
        _criteria = _criteria.copyWith(
          timeMode: TimeFilterMode.customDateRange,
          startDate: picked.start,
          endDate: picked.end,
          clearCustomMonth: true,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    final isVi = l10n.locale == 'vi';

    // Lọc danh mục theo loại giao dịch được chọn
    final visibleCategories = _criteria.type != null
        ? widget.categories.where((c) => c.type == _criteria.type).toList()
        : widget.categories;

    return DraggableScrollableSheet(
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thanh kéo & tiêu đề
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        l10n.filterTransactions,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      if (_criteria.activeFilterCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.teal,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${_criteria.activeFilterCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    // 1. Loại giao dịch (Income / Expense)
                    Text(
                      l10n.type,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.allTypes),
                          selected: _criteria.type == null,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _criteria = _criteria.copyWith(clearType: true);
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: Text(l10n.expense),
                          selected: _criteria.type == 'expense',
                          selectedColor: Colors.red[100],
                          onSelected: (selected) {
                            setState(() {
                              _criteria = _criteria.copyWith(
                                type: selected ? 'expense' : null,
                                clearType: !selected,
                              );
                            });
                          },
                        ),
                        ChoiceChip(
                          label: Text(l10n.income),
                          selected: _criteria.type == 'income',
                          selectedColor: Colors.green[100],
                          onSelected: (selected) {
                            setState(() {
                              _criteria = _criteria.copyWith(
                                type: selected ? 'income' : null,
                                clearType: !selected,
                              );
                            });
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 2. Bộ lọc thời gian (Time Filter)
                    Text(
                      l10n.time,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ChoiceChip(
                          label: Text(l10n.all),
                          selected: _criteria.timeMode == TimeFilterMode.all,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _criteria = _criteria.copyWith(
                                  timeMode: TimeFilterMode.all,
                                  clearCustomMonth: true,
                                  clearStartDate: true,
                                  clearEndDate: true,
                                );
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: Text(isVi ? 'Hôm nay' : 'Today'),
                          selected: _criteria.timeMode == TimeFilterMode.today,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _criteria = _criteria.copyWith(timeMode: TimeFilterMode.today);
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: Text(isVi ? 'Tuần này' : 'This week'),
                          selected: _criteria.timeMode == TimeFilterMode.thisWeek,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _criteria = _criteria.copyWith(timeMode: TimeFilterMode.thisWeek);
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: Text(l10n.thisMonth),
                          selected: _criteria.timeMode == TimeFilterMode.thisMonth,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _criteria = _criteria.copyWith(timeMode: TimeFilterMode.thisMonth);
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: Text(l10n.lastMonth),
                          selected: _criteria.timeMode == TimeFilterMode.lastMonth,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _criteria = _criteria.copyWith(timeMode: TimeFilterMode.lastMonth);
                              });
                            }
                          },
                        ),
                        ChoiceChip(
                          label: Text(isVi ? 'Năm nay' : 'This year'),
                          selected: _criteria.timeMode == TimeFilterMode.thisYear,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _criteria = _criteria.copyWith(timeMode: TimeFilterMode.thisYear);
                              });
                            }
                          },
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.calendar_month, size: 16),
                          label: Text(
                            _criteria.timeMode == TimeFilterMode.customMonth && _criteria.customMonth != null
                                ? '${isVi ? "Tháng " : "Month "}${DateFormat('MM/yyyy').format(_criteria.customMonth!)}'
                                : (isVi ? 'Chọn tháng...' : 'Select month...'),
                          ),
                          backgroundColor: _criteria.timeMode == TimeFilterMode.customMonth
                              ? Colors.teal[100]
                              : null,
                          onPressed: _pickCustomMonth,
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.date_range, size: 16),
                          label: Text(
                            _criteria.timeMode == TimeFilterMode.customDateRange &&
                                    _criteria.startDate != null &&
                                    _criteria.endDate != null
                                ? '${DateFormat('dd/MM').format(_criteria.startDate!)} - ${DateFormat('dd/MM/yyyy').format(_criteria.endDate!)}'
                                : (isVi ? 'Khoảng ngày...' : 'Date range...'),
                          ),
                          backgroundColor: _criteria.timeMode == TimeFilterMode.customDateRange
                              ? Colors.teal[100]
                              : null,
                          onPressed: _pickDateRange,
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 3. Bộ lọc Ví (Multi-wallet)
                    if (widget.wallets.isNotEmpty) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isVi ? 'Ví tài khoản' : 'Wallets',
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                          if (_criteria.selectedWalletIds.isNotEmpty)
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _criteria = _criteria.copyWith(selectedWalletIds: const {});
                                });
                              },
                              child: Text(isVi ? 'Bỏ chọn tất cả' : 'Deselect all'),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          FilterChip(
                            label: Text(isVi ? 'Tất cả ví' : 'All wallets'),
                            selected: _criteria.selectedWalletIds.isEmpty,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _criteria = _criteria.copyWith(selectedWalletIds: const {});
                                });
                              }
                            },
                          ),
                          ...widget.wallets.map((w) {
                            final isSelected = _criteria.selectedWalletIds.contains(w.id);
                            return FilterChip(
                              label: Text(w.name),
                              selected: isSelected,
                              onSelected: (selected) {
                                setState(() {
                                  final newSet = Set<String>.from(_criteria.selectedWalletIds);
                                  if (selected) {
                                    newSet.add(w.id);
                                  } else {
                                    newSet.remove(w.id);
                                  }
                                  _criteria = _criteria.copyWith(selectedWalletIds: newSet);
                                });
                              },
                            );
                          }),
                        ],
                      ),
                      const SizedBox(height: 18),
                    ],

                    // 4. Bộ lọc Danh mục (Multi-category)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.category,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                        if (_criteria.selectedCategoryIds.isNotEmpty)
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _criteria = _criteria.copyWith(selectedCategoryIds: const {});
                              });
                            },
                            child: Text(isVi ? 'Bỏ chọn tất cả' : 'Deselect all'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        FilterChip(
                          label: Text(l10n.allCategories),
                          selected: _criteria.selectedCategoryIds.isEmpty,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() {
                                _criteria = _criteria.copyWith(selectedCategoryIds: const {});
                              });
                            }
                          },
                        ),
                        ...visibleCategories.map((cat) {
                          final isSelected = _criteria.selectedCategoryIds.contains(cat.id);
                          final displayName = l10n.translateCategoryName(cat.id, cat.name);
                          final iconData = CategoryIconData.getIcon(cat.icon) ??
                              (cat.type == 'income' ? Icons.arrow_downward : Icons.arrow_upward);

                          Color bg;
                          if (cat.color != null && cat.color!.isNotEmpty) {
                            try {
                              bg = Color(int.parse(cat.color!.substring(1), radix: 16) + 0xFF000000);
                            } catch (_) {
                              bg = cat.type == 'income' ? Colors.green : Colors.red;
                            }
                          } else {
                            bg = cat.type == 'income' ? Colors.green : Colors.red;
                          }

                          final iconCol = ThemeData.estimateBrightnessForColor(bg) == Brightness.light
                              ? Colors.black87
                              : Colors.white;

                          return FilterChip(
                            avatar: Container(
                              width: 20,
                              height: 20,
                              decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
                              child: Icon(iconData, color: iconCol, size: 12),
                            ),
                            label: Text(displayName),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                final newSet = Set<String>.from(_criteria.selectedCategoryIds);
                                if (selected) {
                                  newSet.add(cat.id);
                                } else {
                                  newSet.remove(cat.id);
                                }
                                _criteria = _criteria.copyWith(selectedCategoryIds: newSet);
                              });
                            },
                          );
                        }),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // 5. Khoảng số tiền (Min - Max Amount)
                    Text(
                      l10n.amountRange,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _minAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.minAmount,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (val) {
                              final sanitized = val.replaceAll(RegExp(r'[^0-9.]'), '');
                              final parsed = double.tryParse(sanitized);
                              _criteria = _criteria.copyWith(
                                minAmount: parsed,
                                clearMinAmount: parsed == null,
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _maxAmountController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: l10n.maxAmount,
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            ),
                            onChanged: (val) {
                              final sanitized = val.replaceAll(RegExp(r'[^0-9.]'), '');
                              final parsed = double.tryParse(sanitized);
                              _criteria = _criteria.copyWith(
                                maxAmount: parsed,
                                clearMaxAmount: parsed == null,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),

              // Action Buttons
              SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _criteria = TransactionFilterCriteria(searchQuery: _criteria.searchQuery);
                            _minAmountController.clear();
                            _maxAmountController.clear();
                          });
                        },
                        child: Text(isVi ? 'Đặt lại' : 'Reset all'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context, _criteria);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.teal,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(l10n.apply),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
