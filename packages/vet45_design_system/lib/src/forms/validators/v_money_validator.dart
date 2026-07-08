/// Built-in money validation for [VMoneyField].
abstract final class VMoneyValidator {
  static const String defaultRequiredMessage = 'Vui lòng nhập số tiền';
  static const String defaultInvalidMessage = 'Số tiền không hợp lệ';

  static String defaultMinMessage(int min) => 'Số tiền tối thiểu là ${format(min)}';
  static String defaultMaxMessage(int max) => 'Số tiền tối đa là ${format(max)}';

  /// Formats an integer amount with Vietnamese thousand separators (`.`).
  static String format(int value) {
    final isNegative = value < 0;
    final digits = value.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(digits[i]);
    }
    return isNegative ? '-${buffer.toString()}' : buffer.toString();
  }

  /// Parses a display string (with `.` separators) into an integer amount.
  static int? parse(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    final normalized = trimmed.replaceAll('.', '');
    return int.tryParse(normalized);
  }

  static bool isValid(
    String value, {
    int? min,
    int? max,
  }) {
    final parsed = parse(value);
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
    int? min,
    int? max,
    String requiredMessage = defaultRequiredMessage,
    String invalidMessage = defaultInvalidMessage,
    String? minMessage,
    String? maxMessage,
  }) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return isRequired ? requiredMessage : null;
    }

    final parsed = parse(trimmed);
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
}
