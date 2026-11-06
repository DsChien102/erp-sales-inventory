import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_draft_errors.dart';

const Map<String, String> _messages = {
  SalesDraftErrorCodes.noPermission: 'Bạn không có quyền thực hiện thao tác này.',
  SalesDraftErrorCodes.dataScopeDenied: 'Cửa hàng hiện tại không còn khả dụng.',
  SalesDraftErrorCodes.staleData: 'Đơn nháp này đã bị xoá hoặc thay đổi ở nơi khác.',
  SalesDraftErrorCodes.idempotencyConflict: 'Yêu cầu bị xung đột',
};

/// TH-05 6.4. Thứ tự: overrides[code] → bảng → fallback.
/// Lỗi không phải AppException ⇒ fallback. Không bao giờ hiện serverMessage hay mã.
String salesDraftErrorMessage(
  Object error, {
  required String fallback,
  Map<String, String> overrides = const {},
}) {
  if (error is! AppException) return fallback;
  return overrides[error.code] ?? _messages[error.code] ?? fallback;
}
