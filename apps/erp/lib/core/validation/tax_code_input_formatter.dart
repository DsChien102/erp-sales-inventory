import 'package:flutter/services.dart';

/// Keeps tax codes as digits, inserting the branch dash for 13 digits.
class TaxCodeInputFormatter extends TextInputFormatter {
  static const maxDigits = 13;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    if (digits.length > maxDigits) {
      digits = digits.substring(0, maxDigits);
    }

    final text = digits.length == maxDigits
        ? '${digits.substring(0, 10)}-${digits.substring(10)}'
        : digits;

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
