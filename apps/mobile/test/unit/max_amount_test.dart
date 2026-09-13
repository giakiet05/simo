import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:simo/utils/app_constants.dart';
import 'package:simo/utils/currency_input_formatter.dart';

void main() {
  group('AppConstants & CurrencyInputFormatter Tests', () {
    test('maxAmount is 9,999,999,999', () {
      expect(AppConstants.maxAmount, equals(9999999999.0));
      expect(AppConstants.maxAmountFormattedVi, equals('9.999.999.999'));
    });

    test('CurrencyInputFormatter formats numbers and allows values <= 9,999,999,999', () {
      final formatter = CurrencyInputFormatter();

      final result1 = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '1000000'),
      );
      expect(result1.text, equals('1,000,000'));

      final resultMax = formatter.formatEditUpdate(
        const TextEditingValue(text: ''),
        const TextEditingValue(text: '9999999999'),
      );
      expect(resultMax.text, equals('9,999,999,999'));
    });

    test('CurrencyInputFormatter rejects values > 9,999,999,999', () {
      final formatter = CurrencyInputFormatter();

      final oldValue = const TextEditingValue(text: '9,999,999,999');
      // User tries to type another digit '0'
      final newValue = const TextEditingValue(text: '9,999,999,9990');

      final result = formatter.formatEditUpdate(oldValue, newValue);
      // Must keep oldValue
      expect(result.text, equals('9,999,999,999'));
    });
  });
}
