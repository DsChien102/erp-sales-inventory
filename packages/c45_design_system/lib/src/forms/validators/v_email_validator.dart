/// Built-in email validation for [VEmailField].
abstract final class VEmailValidator {
  static final RegExp _emailPattern = RegExp(r'^[^@]+@[^@]+\.[^@]+$');

  /// Shortest practical email matching [_emailPattern], e.g. `a@b.c`.
  static const int defaultMinLength = 5;

  /// RFC 5321 maximum email address length.
  static const int defaultMaxLength = 254;

  static const String defaultInvalidEmailMessage = 'Email không hợp lệ';
  static const String defaultRequiredEmailMessage = 'Vui lòng nhập email';

  static String defaultMinLengthEmailMessage(int minLength) =>
      'Email phải có ít nhất $minLength ký tự';

  static String defaultMaxLengthEmailMessage(int maxLength) =>
      'Email không được vượt quá $maxLength ký tự';

  static bool isValid(
    String value, {
    int minLength = defaultMinLength,
    int maxLength = defaultMaxLength,
  }) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return true;
    }
    if (trimmed.length < minLength || trimmed.length > maxLength) {
      return false;
    }
    return _emailPattern.hasMatch(trimmed);
  }

  static String? validate(
    String value, {
    required bool isRequired,
    int minLength = defaultMinLength,
    int maxLength = defaultMaxLength,
    String invalidEmailMessage = defaultInvalidEmailMessage,
    String requiredEmailMessage = defaultRequiredEmailMessage,
    String? minLengthEmailMessage,
    String? maxLengthEmailMessage,
  }) {
    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return isRequired ? requiredEmailMessage : null;
    }

    if (trimmed.length < minLength) {
      return minLengthEmailMessage ?? defaultMinLengthEmailMessage(minLength);
    }

    if (trimmed.length > maxLength) {
      return maxLengthEmailMessage ?? defaultMaxLengthEmailMessage(maxLength);
    }

    if (!_emailPattern.hasMatch(trimmed)) {
      return invalidEmailMessage;
    }

    return null;
  }
}
