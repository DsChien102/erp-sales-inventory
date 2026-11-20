import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';

/// TH-08 6.4 "Khối HĐĐT trên đơn". [overrides] để chỗ gọi giữ câu riêng cho một mã.
String einvoiceErrorMessage(Object? error, {Map<String, String> overrides = const {}}) {
  final raw = error?.toString() ?? '';
  if (error is! AppException) {
    if (raw.contains('PlatformException') || raw.contains('Error while launching')) {
      return 'Không thể mở liên kết xem hóa đơn trên thiết bị. Vui lòng kiểm tra trình duyệt.';
    }
  }

  if (error == null) {
    return 'Không thể thực hiện thao tác hóa đơn điện tử. Vui lòng thử lại.';
  }

  final appEx = error is AppException ? error : AppException.from(error);
  final code = appEx.code;

  if (overrides.containsKey(code)) {
    return overrides[code]!;
  }

  final blockers = appEx.details?['blockers'];
  bool matches(String targetCode) {
    if (code == targetCode) return true;
    if (blockers is Iterable && blockers.contains(targetCode)) return true;
    return false;
  }

  if (matches('NO_PERMISSION')) {
    return 'Bạn không có quyền thực hiện thao tác này.';
  }
  if (matches('STATE_CHANGED')) {
    return 'Trạng thái đơn hàng đã thay đổi. Vui lòng tải lại trang.';
  }
  if (matches('TEMPLATE_NOT_AVAILABLE')) {
    return 'Mẫu hóa đơn đã chọn không còn khả dụng. Vui lòng cập nhật cấu hình phát hành.';
  }
  if (matches('SIGNING_CONFIGURATION_NOT_AVAILABLE')) {
    return 'Hình thức ký không hợp lệ với mẫu hóa đơn. Vui lòng cập nhật cấu hình phát hành.';
  }
  if (matches('UNSUPPORTED_TAX_DATA')) {
    return 'Dữ liệu thuế trên đơn hàng không hợp lệ để phát hành hóa đơn. Vui lòng liên hệ hỗ trợ.';
  }
  if (matches('BUYER_ADDRESS_REQUIRED')) {
    return 'Khách tổ chức có mã số thuế nhưng thiếu địa chỉ xuất hóa đơn. Vui lòng bổ sung thông tin người mua.';
  }
  if (matches('ORDER_FULLY_RETURNED')) {
    return 'Đơn hàng đã trả hết hàng, không cần xuất hóa đơn.';
  }
  if (matches('SOURCE_VERSION_MISMATCH')) {
    return 'Đơn hàng vừa thay đổi (đổi/trả). Vui lòng tải lại rồi phát hành.';
  }
  if (matches('CONFIG_NOT_READY')) {
    return 'Chưa chọn mẫu hóa đơn. Vui lòng cập nhật cấu hình phát hành.';
  }
  if (matches('ISSUANCE_NOT_READY')) {
    return 'Đơn hàng chưa đủ điều kiện phát hành hóa đơn. Kiểm tra thiết lập hóa đơn điện tử và thông tin người mua.';
  }
  if (matches('VALIDATION_ERROR')) {
    return 'Dữ liệu đơn hàng chưa hợp lệ để lập hóa đơn. Vui lòng kiểm tra lại thông tin đơn.';
  }
  if (matches('STALE_VERSION')) {
    return 'Đơn hàng vừa được cập nhật. Vui lòng tải lại rồi thử lại.';
  }
  if (matches('DELIVERY_NOT_SUPPORTED')) {
    return 'Cổng kết nối hóa đơn chưa hỗ trợ tính năng gửi email.';
  }
  if (matches('OPERATION_IN_PROGRESS')) {
    return 'Yêu cầu đang được xử lý, vui lòng chờ giây lát.';
  }
  if (matches('NOT_FOUND')) {
    return 'Không tìm thấy hóa đơn điện tử của đơn hàng này.';
  }
  if (matches('PROVIDER_UNAVAILABLE')) {
    return 'Cổng kết nối hóa đơn tạm thời không khả dụng. Vui lòng thử lại.';
  }
  if (matches('DOCUMENT_UNAVAILABLE')) {
    return 'Tài liệu hóa đơn chưa sẵn sàng. Vui lòng thử lại sau.';
  }
  if (matches('NETWORK_ERROR') ||
      error is TimeoutException ||
      raw.contains('SocketException') ||
      raw.contains('TimeoutException')) {
    return 'Không kết nối được dịch vụ hóa đơn điện tử. Vui lòng thử lại.';
  }

  return 'Không thể thực hiện thao tác hóa đơn điện tử. Vui lòng thử lại.';
}

const einvoiceDeliveryFallbackMessage = 'Không thể gửi hóa đơn lúc này. Vui lòng thử lại.';

/// TH-08 6.4 "Gửi email".
String einvoiceDeliveryErrorMessage(Object? error) {
  if (error == null) return einvoiceDeliveryFallbackMessage;
  final raw = error.toString();
  final appEx = error is AppException ? error : AppException.from(error);
  final code = appEx.code;

  if (code == 'NO_PERMISSION') {
    return 'Bạn không có quyền gửi hóa đơn điện tử.';
  }
  if (code == 'DELIVERY_NOT_SUPPORTED') {
    return 'Cổng kết nối hóa đơn chưa hỗ trợ tính năng gửi email.';
  }
  if (code == 'OPERATION_IN_PROGRESS') {
    return 'Yêu cầu gửi trước đang được xử lý. Vui lòng chờ kết quả.';
  }
  if (code == 'VALIDATION_ERROR') {
    return 'Email người nhận không hợp lệ. Vui lòng kiểm tra lại.';
  }
  if (code == 'NOT_FOUND') {
    return 'Không tìm thấy hóa đơn điện tử của đơn hàng này.';
  }
  if (code == 'NETWORK_ERROR' ||
      code == 'PROVIDER_UNAVAILABLE' ||
      error is TimeoutException ||
      raw.contains('SocketException') ||
      raw.contains('TimeoutException')) {
    return 'Không kết nối được dịch vụ gửi hóa đơn. Vui lòng thử lại.';
  }
  return einvoiceDeliveryFallbackMessage;
}

