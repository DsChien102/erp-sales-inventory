/// Translates state payload keys and values into user-friendly Vietnamese labels.
abstract final class TenantAuditFieldCatalog {
  static const Map<String, String> _fieldLabels = {
    'status': 'Trạng thái',
    'role': 'Vai trò',
    'name': 'Tên',
    'display_name': 'Tên hiển thị',
    'full_name': 'Họ và tên',
    'first_name': 'Tên',
    'last_name': 'Họ',
    'phone': 'Số điện thoại',
    'phone_masked': 'Số điện thoại',
    'email': 'Email',
    'email_masked': 'Email',
    'tax_code': 'Mã số thuế',
    'business_address': 'Địa chỉ kinh doanh',
    'legal_representative_name': 'Người đại diện pháp luật',
    'avatar_url': 'Ảnh đại diện',
    'is_active': 'Trạng thái hoạt động',
    'suspended_reason': 'Lý do tạm ngừng',
    'owner_user_id': 'Mã chủ sở hữu',
    'invitation_id': 'Mã lời mời',
    'membership_id': 'Mã thành viên',
    'version': 'Phiên bản',
    'tenant_id': 'Mã tổ chức',
    'user_id': 'Mã người dùng',
    'created_at': 'Thời gian tạo',
    'updated_at': 'Thời gian cập nhật',
    'expires_at': 'Thời gian hết hạn',
  };

  static const Map<String, String> _valueLabels = {
    'active': 'Đang hoạt động',
    'suspended': 'Tạm ngừng',
    'deactivated': 'Đã tạm ngừng',
    'removed': 'Đã loại bỏ',
    'provisioning': 'Đang khởi tạo',
    'store_owner': 'Chủ sở hữu',
    'store_manager': 'Quản lý chi nhánh',
    'veterinarian': 'Bác sĩ thú y',
    'care_staff': 'Nhân viên chăm sóc',
    'cashier': 'Thu ngân',
    'pending': 'Đang chờ',
    'revoked': 'Đã thu hồi',
    'accepted': 'Đã chấp nhận',
    'true': 'Bật',
    'false': 'Tắt',
  };

  /// Returns user-friendly Vietnamese label for a payload field key.
  static String labelFor(String fieldKey) {
    final direct = _fieldLabels[fieldKey];
    if (direct != null) return direct;

    final lower = fieldKey.toLowerCase();
    final lowerDirect = _fieldLabels[lower];
    if (lowerDirect != null) return lowerDirect;

    // Fallback: replace underscores with spaces and capitalize
    final words = fieldKey.replaceAll('_', ' ').split(' ');
    return words.map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
  }

  /// Formats raw payload value into human-readable string.
  static String formatValue(String fieldKey, Object? value) {
    if (value == null) return '—';
    if (value is bool) return value ? 'Bật' : 'Tắt';

    final text = value.toString().trim();
    if (text.isEmpty) return '—';

    final mapped = _valueLabels[text.toLowerCase()];
    if (mapped != null) return mapped;

    return text;
  }

  /// Checks if a field contains credentials or sensitive tokens.
  static bool isSensitive(String fieldKey) {
    final separated = fieldKey
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)}_${match.group(2)}',
        )
        .toLowerCase();
    final words = separated
        .split(RegExp(r'[^a-z0-9]+'))
        .where((word) => word.isNotEmpty)
        .toList(growable: false);
    final normalized = words.join();
    const sensitiveFragments = <String>[
      'credential',
      'token',
      'password',
      'secret',
      'hash',
      'otp',
      'cookie',
      'bearer',
      'nonce',
      'session',
      'ciphertext',
    ];
    if (sensitiveFragments.any(normalized.contains)) return true;
    if (normalized.contains('apikey') || normalized.contains('privatekey')) {
      return true;
    }
    return words.any(
      (word) =>
          word == 'pin' ||
          word == 'auth' ||
          word == 'authn' ||
          word == 'authz' ||
          word == 'authentication' ||
          word == 'authorization',
    );
  }
}
