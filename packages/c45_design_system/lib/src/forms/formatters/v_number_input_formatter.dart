import 'package:flutter/services.dart';

import '../validators/v_number_validator.dart';

/// Restricts number input to digits (optional leading minus) or decimal (`.`),
/// and formats thousand separators as `,`.
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

    final isNegative = text.startsWith('-');
    final digits = isNegative ? text.substring(1) : text;
    if (digits.isEmpty) {
      return TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }

    final parsed = int.tryParse(digits);
    if (parsed == null) {
      return oldValue;
    }

    final formatted = VNumberValidator.format(
      isNegative ? -parsed : parsed,
      allowDecimal: false,
    );
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }

  TextEditingValue _formatDecimal(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var isNegative = false;
    var hasDot = false;
    final integerDigits = StringBuffer();
    final fractionDigits = StringBuffer();

    for (var i = 0; i < newValue.text.length; i++) {
      final char = newValue.text[i];
      if (RegExp(r'[0-9]').hasMatch(char)) {
        if (hasDot) {
          if (fractionDigits.length >= decimalPlaces) {
            continue;
          }
          fractionDigits.write(char);
        } else {
          integerDigits.write(char);
        }
      } else if (char == '.' && !hasDot) {
        hasDot = true;
      } else if (allowNegative && char == '-' && !isNegative && integerDigits.isEmpty && !hasDot) {
        isNegative = true;
      }
    }

    if (integerDigits.isEmpty && !hasDot && !isNegative) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(offset: 0),
      );
    }

    if (integerDigits.isEmpty && isNegative && !hasDot) {
      return const TextEditingValue(
        text: '-',
        selection: TextSelection.collapsed(offset: 1),
      );
    }

    final intPartRaw = integerDigits.isEmpty ? '0' : integerDigits.toString();
    final intParsed = int.tryParse(intPartRaw);
    if (intParsed == null) {
      return oldValue;
    }

    final groupedInt = VNumberValidator.format(
      intParsed,
      allowDecimal: false,
    );
    final buffer = StringBuffer();
    if (isNegative) {
      buffer.write('-');
    }
    buffer.write(groupedInt);
    if (hasDot) {
      buffer.write('.');
      buffer.write(fractionDigits.toString());
    }

    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
