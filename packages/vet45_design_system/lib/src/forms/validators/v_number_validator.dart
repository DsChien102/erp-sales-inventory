/// Built-in number validation for [VNumberField].
abstract final class VNumberValidator {
  static const String defaultRequiredMessage = 'Vui lòng nhập số';
  static const String defaultInvalidMessage = 'Số không hợp lệ';

  static String defaultMinMessage(num min) => 'Giá trị tối thiểu là $min';
  static String defaultMaxMessage(num max) => 'Giá trị tối đa là $max';

  /// Formats [value] with thousand separators (`,`) and optional decimal (`.`).
  static String format(
    num value, {
    required bool allowDecimal,
    int decimalPlaces = 2,
  }) {
    if (!allowDecimal) {
      return _formatGroupedInteger(value.round());
    }

    final isNegative = value < 0;
    final abs = value.abs();
    final raw = abs.toString();
    final parts = raw.split('.');
    final grouped = _groupDigits(parts[0]);
    if (parts.length == 1) {
      return isNegative ? '-$grouped' : grouped;
    }

    var fraction = parts[1];
    if (fraction.length > decimalPlaces) {
      fraction = fraction.substring(0, decimalPlaces);
    }
    final result = '$grouped.$fraction';
    return isNegative ? '-$result' : result;
  }

  /// Parses display text into a [num].
  ///
  /// Thousand separator: `,`. Decimal separator: `.` (when [allowDecimal]).
  static num? parse(
    String text, {
    required bool allowDecimal,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    final normalized = trimmed.replaceAll(',', '');
    if (allowDecimal) {
      return double.tryParse(normalized);
    }

    return int.tryParse(normalized);
  }

  static bool isValid(
    String value, {
    required bool allowDecimal,
    num? min,
    num? max,
  }) {
    final parsed = parse(value, allowDecimal: allowDecimal);
    if (parsed == null) {
      return value.trim().isEmpty;
    }
    if (min != null && parsed < min) {
      return false;
    }
    if (max != null && parsed > max) {
      return false;
    }
    return true;
  }

  static String? validate(
    String value, {
    required bool isRequired,
    required bool allowDecimal,
    num? min,
    num? max,
    String requiredMessage = defaultRequiredMessage,
    String invalidMessage = defaultInvalidMessage,
    String? minMessage,
    String? maxMessage,
  }) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return isRequired ? requiredMessage : null;
    }

    final parsed = parse(trimmed, allowDecimal: allowDecimal);
    if (parsed == null) {
      return invalidMessage;
    }

    if (min != null && parsed < min) {
      return minMessage ?? defaultMinMessage(min);
    }

    if (max != null && parsed > max) {
      return maxMessage ?? defaultMaxMessage(max);
    }

    return null;
  }

  static String _formatGroupedInteger(int value) {
    final isNegative = value < 0;
    final grouped = _groupDigits(value.abs().toString());
    return isNegative ? '-$grouped' : grouped;
  }

  static String _groupDigits(String digits) {
    if (digits.isEmpty) {
      return '0';
    }
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}
