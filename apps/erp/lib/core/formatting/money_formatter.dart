// ignore_for_file: unnecessary_brace_in_string_interps

/// ERP display formatting for money amounts (VND grouping + suffix).
///
/// Distinct from design-system [VMoneyValidator] input formatting (comma separators).
abstract final class MoneyFormatter {
  /// Formats minor units for display (`1.245.000đ` / `-990.000đ` / `1.245.000 USD`).
  static String format({
    required int amountMinor,
    String currencyCode = 'VND',
  }) {
    final grouped = formatMinorPlain(amountMinor);
    if (currencyCode == 'VND') {
      return '${grouped}đ';
    }
    return '$grouped $currencyCode';
  }

  /// Convenience formatter for raw minor amounts in VND.
  static String formatMinor(int amountMinor) {
    return format(amountMinor: amountMinor);
  }

  /// Grouped digits only, without the currency suffix (`360.000` or `-990.000`).
  ///
  /// Use for editable inputs that render their own currency suffix so the
  /// unit does not appear twice.
  static String formatMinorPlain(int amountMinor) {
    final isNegative = amountMinor < 0;
    final digits = amountMinor.abs().toString();
    final buffer = StringBuffer();
    if (isNegative) {
      buffer.write('-');
    }
    for (var i = 0; i < digits.length; i++) {
      final fromEnd = digits.length - i;
      buffer.write(digits[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buffer.write('.');
      }
    }
    return buffer.toString();
  }

  /// Parses a user-entered VND string back to a raw minor amount.
  ///
  /// Ignores grouping separators, the currency suffix, and whitespace.
  static int parseMinor(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return 0;
    return int.tryParse(digits) ?? 0;
  }
}
