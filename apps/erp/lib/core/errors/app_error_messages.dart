/// Câu tiếng Việt cho mã lỗi chung. Mã riêng từng nghiệp vụ không nằm ở đây;
/// feature truyền overrides vào `AppException.userMessage`.
abstract final class AppErrorMessages {
  static String of(String code) => _messages[code] ?? _messages['SYSTEM_ERROR']!;

  static const Map<String, String> _messages = {
    'NO_PERMISSION': 'Bạn không có quyền thực hiện thao tác này.',
    'NOT_FOUND': 'Không tìm thấy dữ liệu. Có thể dữ liệu đã bị xoá.',
    'VALIDATION_ERROR': 'Dữ liệu chưa hợp lệ. Vui lòng kiểm tra lại.',
    'STATE_CHANGED': 'Dữ liệu vừa được thay đổi ở nơi khác. Vui lòng tải lại.',
    'AUTHENTICATION_REQUIRED': 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    'TENANT_SUSPENDED': 'Tổ chức đang tạm ngừng hoạt động.',
    'TENANT_CLOSED': 'Tổ chức đã đóng.',
    'NETWORK_ERROR': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.',
    'IDEMPOTENCY_CONFLICT': 'Yêu cầu bị trùng. Vui lòng thử lại.',
    'SYSTEM_ERROR': 'Đã có lỗi xảy ra. Vui lòng thử lại.',
  };
}
