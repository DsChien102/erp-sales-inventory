/// Built-in select validation for [VSelect].
abstract final class VSelectValidator {
  static const String defaultRequiredMessage = 'Vui lòng chọn một giá trị';

  static bool isValid<T>(T? value) => value != null;

  static String? validate<T>(
    T? value, {
    required bool isRequired,
    String requiredMessage = defaultRequiredMessage,
  }) {
    if (value == null && isRequired) {
      return requiredMessage;
    }
    return null;
  }
}
