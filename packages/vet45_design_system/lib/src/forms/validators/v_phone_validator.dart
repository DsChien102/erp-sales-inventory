/// Format validation only: 9–11 ASCII digits with optional spaces.
/// Does not verify country/carrier prefixes or whether a number exists.
abstract final class VPhoneValidator {
  static const defaultRequiredMessage = 'Vui lòng nhập số điện thoại';
  static const defaultInvalidMessage = 'Số điện thoại không hợp lệ';
  static final _invalidCharacters = RegExp(r'[^0-9 ]');

  static String? validate(
    String value, {
    bool isRequired = false,
    String requiredMessage = defaultRequiredMessage,
    String invalidMessage = defaultInvalidMessage,
  }) {
    if (_invalidCharacters.hasMatch(value)) return invalidMessage;
    final digits = value.replaceAll(' ', '');
    if (digits.isEmpty) return isRequired ? requiredMessage : null;
    return digits.length >= 9 && digits.length <= 11 ? null : invalidMessage;
  }
}
