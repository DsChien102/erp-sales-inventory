import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_checkout_errors.dart';

const Map<String, String> _messages = {
  SalesCheckoutErrorCodes.noPermission: 'Bạn không có quyền thực hiện thao tác này.',
  SalesCheckoutErrorCodes.dataScopeDenied: 'Cửa hàng hiện tại không còn khả dụng.',
  SalesCheckoutErrorCodes.contextInvalid: 'Ngữ cảnh thanh toán không hợp lệ.',
  SalesCheckoutErrorCodes.idempotencyConflict: 'Yêu cầu bị xung đột',
  SalesCheckoutErrorCodes.productNotSellable: 'Sản phẩm đã ngừng bán. Vui lòng quay lại đơn.',
  SalesCheckoutErrorCodes.priceChanged: 'Giá đã thay đổi. Vui lòng quay lại kiểm tra.',
  SalesCheckoutErrorCodes.pricingBlocked: 'Sản phẩm này chưa có giá bán.',
  SalesCheckoutErrorCodes.insufficientStock: 'Không đủ tồn kho để bán.',
  SalesCheckoutErrorCodes.checkoutBlocked: 'Đơn chưa đủ điều kiện thanh toán.',
};

/// TH-05 6.4. Thứ tự: overrides[code] → bảng → fallback.
/// Lỗi không phải AppException ⇒ fallback. Không bao giờ hiện serverMessage hay mã.
String salesCheckoutErrorMessage(
  Object error, {
  required String fallback,
  Map<String, String> overrides = const {},
}) {
  if (error is! AppException) return fallback;
  return overrides[error.code] ?? _messages[error.code] ?? fallback;
}
