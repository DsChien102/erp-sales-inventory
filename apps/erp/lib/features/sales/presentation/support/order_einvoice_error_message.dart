/// Ánh xạ lỗi kỹ thuật của luồng HĐĐT sang câu người bán hàng đọc được.
///
/// Dùng bởi [OrderEInvoiceCubit] khi emit `errorMessage`. Không bao giờ trả
/// nguyên văn exception, mã RPC, token provider hay chi tiết Postgres.
abstract final class OrderEInvoiceErrorMessage {
  const OrderEInvoiceErrorMessage._();

  static const _actionFallback = 'Không thể thực hiện thao tác hóa đơn điện tử. Vui lòng thử lại.';

  /// Trả về câu tiếng Việt tương ứng với [error]; không bao giờ lộ chi tiết kỹ thuật.
  static String of(Object? error) {
    final raw = error?.toString() ?? '';
    if (raw.isEmpty) return _actionFallback;

    if (raw.contains('NO_PERMISSION') || raw.contains('permission')) {
      return 'Bạn không có quyền thực hiện thao tác này.';
    }
    if (raw.contains('STATE_CHANGED') || raw.contains('order_version_mismatch')) {
      return 'Trạng thái đơn hàng đã thay đổi. Vui lòng tải lại trang.';
    }
    if (raw.contains('TEMPLATE_NOT_AVAILABLE')) {
      return 'Mẫu hóa đơn đã chọn không còn khả dụng. '
          'Vui lòng cập nhật cấu hình phát hành.';
    }
    if (raw.contains('SIGNING_CONFIGURATION_NOT_AVAILABLE')) {
      return 'Hình thức ký không hợp lệ với mẫu hóa đơn. '
          'Vui lòng cập nhật cấu hình phát hành.';
    }
    if (raw.contains('UNSUPPORTED_TAX_DATA')) {
      return 'Dữ liệu thuế trên đơn hàng không hợp lệ để phát hành hóa đơn. '
          'Vui lòng liên hệ hỗ trợ.';
    }
    if (raw.contains('BUYER_ADDRESS_REQUIRED')) {
      return 'Khách tổ chức có mã số thuế nhưng thiếu địa chỉ xuất hóa đơn. '
          'Vui lòng bổ sung thông tin người mua.';
    }
    if (raw.contains('ISSUANCE_NOT_READY')) {
      return 'Đơn hàng chưa đủ điều kiện phát hành hóa đơn. '
          'Kiểm tra thiết lập hóa đơn điện tử và thông tin người mua.';
    }
    if (raw.contains('VALIDATION_ERROR')) {
      return 'Dữ liệu đơn hàng chưa hợp lệ để lập hóa đơn. '
          'Vui lòng kiểm tra lại thông tin đơn.';
    }
    if (raw.contains('STALE_VERSION')) {
      return 'Đơn hàng vừa được cập nhật. Vui lòng tải lại rồi thử lại.';
    }
    if (raw.contains('DELIVERY_NOT_SUPPORTED')) {
      return 'Cổng kết nối hóa đơn chưa hỗ trợ tính năng gửi email.';
    }
    if (raw.contains('OPERATION_IN_PROGRESS')) {
      return 'Yêu cầu đang được xử lý, vui lòng chờ giây lát.';
    }
    if (raw.contains('NOT_FOUND')) {
      return 'Không tìm thấy hóa đơn điện tử của đơn hàng này.';
    }
    if (raw.contains('PROVIDER_UNAVAILABLE')) {
      return 'Cổng kết nối hóa đơn tạm thời không khả dụng. Vui lòng thử lại.';
    }
    if (raw.contains('DOCUMENT_UNAVAILABLE')) {
      return 'Tài liệu hóa đơn chưa sẵn sàng. Vui lòng thử lại sau.';
    }
    if (raw.contains('DEPENDENCY_UNAVAILABLE') ||
        raw.contains('SocketException') ||
        raw.contains('TimeoutException')) {
      return 'Không kết nối được dịch vụ hóa đơn điện tử. Vui lòng thử lại.';
    }
    if (raw.contains('PlatformException') || raw.contains('Error while launching')) {
      return 'Không thể mở liên kết xem hóa đơn trên thiết bị. '
          'Vui lòng kiểm tra trình duyệt.';
    }
    return _actionFallback;
  }
}
