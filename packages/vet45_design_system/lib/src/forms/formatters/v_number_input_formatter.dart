import 'package:flutter/services.dart';

/// Restricts number input to digits (and optional leading minus) or decimal (VN `,`).
class VNumberInputFormatter extends TextInputFormatter {
  const VNumberInputFormatter({
    this.allowDecimal = false,
    this.allowNegative = false,
    this.decimalPlaces = 2,
  });

  final bool allowDecimal;
  final bool allowNegative;
  final int decimalPlaces;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }

    if (allowDecimal) {
      return _formatDecimal(oldValue, newValue);
    }

    return _formatInteger(oldValue, newValue);
  }

  TextEditingValue _formatInteger(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    for (var i = 0; i < newValue.text.length; i++) {
      final char = newValue.text[i];
      if (RegExp(r'[0-9]').hasMatch(char)) {
        buffer.write(char);
      } else if (allowNegative && char == '-' && buffer.isEmpty) {
        buffer.write(char);
      }
    }

    final text = buffer.toString();
    if (text == '-') {
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    if (text.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  TextEditingValue _formatDecimal(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final buffer = StringBuffer();
    var hasComma = false;
    var decimalCount = 0;

    for (var i = 0; i < newValue.text.length; i++) {
      final char = newValue.text[i];
      if (RegExp(r'[0-9]').hasMatch(char)) {
        if (hasComma) {
          if (decimalCount >= decimalPlaces) {
            continue;
          }
          decimalCount++;
        }
        buffer.write(char);
      } else if (char == ',' && !hasComma) {
        hasComma = true;
        buffer.write(char);
      } else if (allowNegative && char == '-' && buffer.isEmpty) {
        buffer.write(char);
      }
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
