/// Kết quả validate mã kích hoạt.
enum ActivationCodeResult {
  /// Mã hợp lệ — tài khoản đã tồn tại → về login.
  existingAccount,

  /// Mã hợp lệ — chưa có tài khoản → sang form đăng ký.
  newAccount,

  /// ID-S-01: Mã kích hoạt không hợp lệ.
  invalidCode,

  /// ID-S-02: Mã kích hoạt đã hết hạn.
  expiredCode,

  /// ID-S-03: Lời mời đã bị thu hồi.
  revokedInvitation,

  /// ID-S-04: Không thể xác thực mã (lỗi kết nối).
  networkError,
}

class FakeActivationData {
  /// Mã kích hoạt giả định dành cho tài khoản đã tồn tại.
  static const String fakeCode = '123456';

  /// Email mặc định được gửi mã kích hoạt.
  static const String fakeEmail = 'nhhaha@gmail.com';

  // --- Mã giả định cho từng trạng thái lỗi ---

  /// ID-S-01: Mã không hợp lệ.
  static const String invalidCode = '000000';

  /// ID-S-02: Mã đã hết hạn.
  static const String expiredCode = '111111';

  /// ID-S-03: Lời mời đã bị thu hồi.
  static const String revokedCode = '222222';

  /// ID-S-04: Không thể xác thực (lỗi kết nối).
  static const String networkErrorCode = '333333';

  /// Mã hợp lệ cho tài khoản mới (chưa tồn tại).
  static const String newAccountCode = '654321';

  /// Validate mã kích hoạt và trả về kết quả tương ứng.
  static ActivationCodeResult validateCode(String code) {
    final trimmed = code.trim();
    return switch (trimmed) {
      _ when trimmed == fakeCode => ActivationCodeResult.existingAccount,
      _ when trimmed == invalidCode => ActivationCodeResult.invalidCode,
      _ when trimmed == expiredCode => ActivationCodeResult.expiredCode,
      _ when trimmed == revokedCode => ActivationCodeResult.revokedInvitation,
      _ when trimmed == networkErrorCode => ActivationCodeResult.networkError,
      // Mọi mã khác → tài khoản mới (chưa tồn tại)
      _ => ActivationCodeResult.newAccount,
    };
  }

  /// Kiểm tra xem mã nhập vào có phải mã của tài khoản đã tồn tại hay không.
  static bool isExistingAccountCode(String code) {
    return code.trim() == fakeCode;
  }
}
