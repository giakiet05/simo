class AppConstants {
  /// Maximum amount allowed for single transaction, wallet balance, budget, etc.
  static const double maxAmount = 9999999999.0;
  static const String maxAmountFormattedVi = '9.999.999.999';
  static const String maxAmountFormattedEn = '9,999,999,999';

  static String maxAmountError(dynamic l10n) {
    final isVi = l10n.locale == 'vi';
    return isVi
        ? 'Số tiền tối đa là $maxAmountFormattedVi'
        : 'Maximum amount is $maxAmountFormattedEn';
  }
}
