/// Built-in number validation for [VNumberField].
abstract final class VNumberValidator {
  static const String defaultRequiredMessage = 'Vui lòng nhập số';
  static const String defaultInvalidMessage = 'Số không hợp lệ';

  static String defaultMinMessage(num min) => 'Giá trị tối thiểu là $min';
  static String defaultMaxMessage(num max) => 'Giá trị tối đa là $max';

  /// Parses display text into a [num]. Uses `,` as decimal separator (VN locale).
  static num? parse(
    String text, {
    required bool allowDecimal,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    if (allowDecimal) {
      final normalized = trimmed.replaceAll(',', '.');
      return double.tryParse(normalized);
    }

    return int.tryParse(trimmed);
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
}
