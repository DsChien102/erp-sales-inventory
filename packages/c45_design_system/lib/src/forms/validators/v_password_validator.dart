/// Built-in password validation for [VPasswordField].
///
/// Does not trim input — leading/trailing spaces are significant.
abstract final class VPasswordValidator {
  static const int defaultMinLength = 8;
  static const int defaultMaxLength = 128;

  static const String defaultRequiredPasswordMessage = 'Vui lòng nhập mật khẩu';

  static String defaultMinLengthPasswordMessage(int minLength) =>
      'Mật khẩu phải có ít nhất $minLength ký tự';

  static String defaultMaxLengthPasswordMessage(int maxLength) =>
      'Mật khẩu không được vượt quá $maxLength ký tự';

  static bool isValid(
    String value, {
    int minLength = defaultMinLength,
    int maxLength = defaultMaxLength,
  }) {
    if (value.isEmpty) {
      return true;
    }
    return value.length >= minLength && value.length <= maxLength;
  }

  static String? validate(
    String value, {
    required bool isRequired,
    int minLength = defaultMinLength,
    int maxLength = defaultMaxLength,
    String requiredPasswordMessage = defaultRequiredPasswordMessage,
    String? minLengthPasswordMessage,
    String? maxLengthPasswordMessage,
  }) {
    if (value.isEmpty) {
      return isRequired ? requiredPasswordMessage : null;
    }

    if (value.length < minLength) {
      return minLengthPasswordMessage ??
          defaultMinLengthPasswordMessage(minLength);
    }

    if (value.length > maxLength) {
      return maxLengthPasswordMessage ??
          defaultMaxLengthPasswordMessage(maxLength);
    }

    return null;
  }
}
