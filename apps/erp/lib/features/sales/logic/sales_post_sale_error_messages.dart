import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models.dart';

const Map<String, String> _errorMessages = {
  'NO_PERMISSION': 'Bạn không có quyền thực hiện thao tác này.',
  'DATA_SCOPE_DENIED': 'Cửa hàng hiện tại không còn khả dụng.',
  'CONTEXT_INVALID': 'Dữ liệu không hợp lệ.',
  'FIELD_NOT_ALLOWED': 'Dữ liệu không hợp lệ.',
  'IDEMPOTENCY_CONFLICT': 'Yêu cầu bị xung đột',
  'IN_PROGRESS': 'Yêu cầu đang được xử lý, vui lòng chờ.',
  'STALE_VERSION': 'Đơn hàng đã thay đổi. Hãy tải lại chi tiết rồi thử lại.',
  'NOT_FOUND': 'Đơn hàng không tồn tại hoặc đã bị xóa.',
  'COMPETING_CANCELLATION': 'Đơn đã được hủy.',
  'RETURN_EXCHANGE_BLOCKED': 'Không thể đổi/trả.',
  'RETURN_QUANTITY_EXCEEDED': 'Số lượng trả vượt số còn có thể trả.',
  'INVALID_QUANTITY': 'Số lượng không hợp lệ với đơn vị bán.',
  'PRODUCT_NOT_SELLABLE': 'Sản phẩm đã ngừng bán. Vui lòng quay lại đơn.',
  'PRICING_BLOCKED': 'Sản phẩm này chưa có giá bán.',
  'INSUFFICIENT_STOCK': 'Không đủ tồn kho để đổi hàng.',
  'NETWORK_ERROR': 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra lại mạng.',
};

const Map<String, String> _blockerMessages = {
  'PAYMENT_ALREADY_COLLECTED': 'Đơn đã có thanh toán, vui lòng đổi/trả',
  'ORDER_ALREADY_CANCELLED': 'Đơn đã được hủy.',
  'COMPETING_CANCELLATION': 'Đơn đã được hủy.',
  'RETURN_EXCHANGE_CONFLICT': 'Đơn đã có phiếu đổi/trả, không thể hủy.',
  'DRAFT_RETURN_ACTIVE': 'Đơn đang có phiếu đổi/trả chưa hoàn tất.',
};

/// Trả về câu thông báo lỗi cho các thao tác sau bán hàng (huỷ đơn, đổi/trả).
/// Thứ tự ưu tiên: [overrides] -> bảng A -> [fallback].
/// Nếu `error` không phải là `AppException` thì trả về [fallback].
String salesPostSaleErrorMessage(
  Object error, {
  required String fallback,
  Map<String, String> overrides = const {},
}) {
  if (error is! AppException) return fallback;
  if (overrides.containsKey(error.code)) {
    return overrides[error.code]!;
  }
  if (error.code == 'INSUFFICIENT_STOCK') {
    final serverMsg = error.serverMessage?.trim();
    if (serverMsg != null && serverMsg.isNotEmpty) {
      return serverMsg;
    }
  }
  return _errorMessages[error.code] ?? fallback;
}

/// Trả về câu thông báo cho blocker theo bảng B, hoặc [fallback] nếu không có trong bảng.
String salesBlockerMessage(
  SalesBlockerDto blocker, {
  required String fallback,
}) {
  return _blockerMessages[blocker.code] ?? fallback;
}

/// Địa phương hoá danh sách blockers sang tiếng Việt, giữ nguyên `code` và `field`,
/// loại bỏ các câu trùng lặp trước khi đưa vào state.
List<SalesBlockerDto> localizeBlockers(
  List<SalesBlockerDto> blockers, {
  required String fallback,
}) {
  final seen = <String>{};
  final result = <SalesBlockerDto>[];
  for (final b in blockers) {
    final msg = salesBlockerMessage(b, fallback: fallback);
    if (seen.add(msg)) {
      result.add(SalesBlockerDto(code: b.code, message: msg, field: b.field));
    }
  }
  return result;
}

