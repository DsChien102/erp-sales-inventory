import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_rpc_errors.dart';

const Set<String> _cancellationStableCodes = {
  'NOT_FOUND',
  'NO_PERMISSION',
  'DATA_SCOPE_DENIED',
  'CANCELLATION_BLOCKED',
  'STALE_VERSION',
  'IDEMPOTENCY_CONFLICT',
  'IMPACT_PENDING',
  'DEPENDENCY_UNAVAILABLE',
  'IN_PROGRESS',
  'CONTEXT_INVALID',
  'FIELD_NOT_ALLOWED',
  'NETWORK_ERROR',
};

/// Chuẩn hoá lỗi huỷ đơn bán hàng (S23–S27):
/// - Giữ các mã nghiệp vụ ổn định và lỗi mạng.
/// - PERMISSION_DENIED → NO_PERMISSION.
/// - Các mã lạ / không nhận dạng được / FormatException → SYSTEM_ERROR.
AppException salesCancellationException(Object error) {
  final appError = error is AppException ? error : AppException.from(error);
  if (_cancellationStableCodes.contains(appError.code)) return appError;
  final nested = unwrapNestedSalesRpcError(
    appError.serverMessage,
    stableCodes: _cancellationStableCodes,
  );
  if (nested != null) return nested;
  return AppException('SYSTEM_ERROR', cause: error);
}

