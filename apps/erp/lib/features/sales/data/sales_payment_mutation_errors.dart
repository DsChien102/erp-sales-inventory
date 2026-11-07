import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_rpc_errors.dart';

const Set<String> _paymentMutationStableCodes = {
  'NO_PERMISSION',
  'DATA_SCOPE_DENIED',
  'CONTEXT_INVALID',
  'REFERENCE_UNAVAILABLE',
  'IDEMPOTENCY_CONFLICT',
  'ORDER_CANCELLED',
  'OVERPAYMENT_NOT_ALLOWED',
  'NETWORK_ERROR',
};

/// Chuẩn hoá lỗi ghi nhận thanh toán (8-B3 Q6):
/// - Giữ các mã Q6: NO_PERMISSION (server PERMISSION_DENIED), DATA_SCOPE_DENIED,
///   CONTEXT_INVALID, REFERENCE_UNAVAILABLE, IDEMPOTENCY_CONFLICT, ORDER_CANCELLED,
///   OVERPAYMENT_NOT_ALLOWED, NETWORK_ERROR.
/// - Các mã khác / lỗi đọc JSON / FormatException → SYSTEM_ERROR.
AppException salesPaymentMutationException(Object error) {
  final appError = error is AppException ? error : AppException.from(error);
  if (_paymentMutationStableCodes.contains(appError.code)) return appError;
  final nested = unwrapNestedSalesRpcError(
    appError.serverMessage,
    stableCodes: _paymentMutationStableCodes,
  );
  if (nested != null) return nested;
  return AppException('SYSTEM_ERROR', cause: error);
}

