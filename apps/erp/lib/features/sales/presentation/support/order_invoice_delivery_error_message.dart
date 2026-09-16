/// Safe Vietnamese copy for SG-07 send/resend delivery errors.
///
/// Never returns raw RPC codes, exception dumps, recipient emails, or provider
/// payloads.
abstract final class OrderInvoiceDeliveryErrorMessage {
  static const fallback = 'Không thể gửi hóa đơn lúc này. Vui lòng thử lại.';

  static String of(Object? error) {
    final raw = error?.toString() ?? '';
    if (raw.contains('NO_PERMISSION')) {
      return 'Bạn không có quyền gửi hóa đơn điện tử.';
    }
    if (raw.contains('DELIVERY_NOT_SUPPORTED')) {
      return 'Cổng kết nối hóa đơn chưa hỗ trợ tính năng gửi email.';
    }
    if (raw.contains('OPERATION_IN_PROGRESS')) {
      return 'Yêu cầu gửi trước đang được xử lý. Vui lòng chờ kết quả.';
    }
    if (raw.contains('VALIDATION_ERROR')) {
      return 'Email người nhận không hợp lệ. Vui lòng kiểm tra lại.';
    }
    if (raw.contains('NOT_FOUND')) {
      return 'Không tìm thấy hóa đơn điện tử của đơn hàng này.';
    }
    if (raw.contains('DEPENDENCY_UNAVAILABLE') ||
        raw.contains('PROVIDER_UNAVAILABLE') ||
        raw.contains('SocketException') ||
        raw.contains('TimeoutException')) {
      return 'Không kết nối được dịch vụ gửi hóa đơn. Vui lòng thử lại.';
    }
    return fallback;
  }
}
