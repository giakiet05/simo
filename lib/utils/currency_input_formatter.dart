import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'app_constants.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  final double maxAmount;

  CurrencyInputFormatter({this.maxAmount = AppConstants.maxAmount});

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    String clean = newValue.text.replaceAll(',', '');
    final number = int.tryParse(clean);
    if (number == null) return oldValue;
    if (number > maxAmount) return oldValue;

    final formatted = NumberFormat('#,###').format(number);
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
