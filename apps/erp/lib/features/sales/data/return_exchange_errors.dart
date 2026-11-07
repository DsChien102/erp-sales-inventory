import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_rpc_errors.dart';

const Set<String> _returnExchangeStableCodes = {
  'NOT_FOUND',
  'NO_PERMISSION',
  'DATA_SCOPE_DENIED',
  'RETURN_EXCHANGE_BLOCKED',
  'RETURN_QUANTITY_EXCEEDED',
  'STALE_VERSION',
  'PRICE_CHANGED',
  'PRICING_BLOCKED',
  'IDEMPOTENCY_CONFLICT',
  'IMPACT_PENDING',
  'DEPENDENCY_UNAVAILABLE',
  'COMPETING_CANCELLATION',
  'CONTEXT_INVALID',
  'IN_PROGRESS',
  'INVALID_QUANTITY',
  'PRODUCT_NOT_SELLABLE',
  'PROJECTION_PENDING',
  'NETWORK_ERROR',
};

/// Chuẩn hoá lỗi đổi/trả bán hàng (SG-10…SG-15):
/// - Giữ các mã nghiệp vụ ổn định và lỗi mạng.
/// - PERMISSION_DENIED → NO_PERMISSION.
/// - Giữ nguyên `details` (đặc biệt là `details['blockers']` của RETURN_EXCHANGE_BLOCKED).
/// - Các mã lạ / FormatException → SYSTEM_ERROR.
AppException returnExchangeException(Object error) {
  final appError = error is AppException ? error : AppException.from(error);
  if (_returnExchangeStableCodes.contains(appError.code)) return appError;
  final nested = unwrapNestedSalesRpcError(
    appError.serverMessage,
    stableCodes: _returnExchangeStableCodes,
  );
  if (nested != null) return nested;
  return AppException('SYSTEM_ERROR', cause: error);
}

