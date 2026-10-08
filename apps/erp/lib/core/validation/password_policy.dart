/// Chính sách mật khẩu dùng chung cho mọi luồng đặt/đổi mật khẩu.
/// Tối thiểu 8 ký tự, có ít nhất 1 số và 1 ký tự đặc biệt (không phải chữ hoặc số).
abstract final class PasswordPolicy {
  static const int minLength = 8;

  /// Mô tả yêu cầu cho helperText của field.
  static const String requirementText =
      'Tối thiểu 8 ký tự, gồm 1 số và 1 ký tự đặc biệt.';

  /// Thông báo khi mật khẩu không đạt policy (không tính trường hợp rỗng).
  static const String violationMessage =
      'Mật khẩu phải có ít nhất 8 ký tự, gồm 1 số và 1 ký tự đặc biệt';

  static final RegExp _digit = RegExp(r'\d');
  static final RegExp _special = RegExp(r'[^A-Za-z0-9]');

  /// Trả về thông báo lỗi (dùng cho errorText) hoặc `null` nếu hợp lệ.
  static String? validate(String value) {
    if (value.isEmpty) {
      return 'Vui lòng nhập mật khẩu';
    }
    final okLength = value.length >= minLength;
    final okDigit = _digit.hasMatch(value);
    final okSpecial = _special.hasMatch(value);
    if (okLength && okDigit && okSpecial) {
      return null;
    }
    return violationMessage;
  }

  static bool isValid(String value) => value.isNotEmpty && validate(value) == null;
}
