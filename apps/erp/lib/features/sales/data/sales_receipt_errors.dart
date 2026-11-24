import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_rpc_errors.dart';

const Set<String> _stableCodes = {
  'NOT_FOUND',
  'NO_PERMISSION', // server PERMISSION_DENIED
  'PROJECTION_PENDING',
  'DATA_SCOPE_DENIED',
  'STALE_VERSION',
  'IDEMPOTENCY_CONFLICT',
  'DEPENDENCY_UNAVAILABLE',
  'CONTEXT_INVALID',
  'NETWORK_ERROR',
};

/// Q5: 8 mã ổn định của gateway phiếu + NETWORK_ERROR → giữ; còn lại SYSTEM_ERROR.
AppException salesReceiptException(Object error) {
  final appError = error is AppException ? error : AppException.from(error);
  if (_stableCodes.contains(appError.code)) return appError;
  final nested = unwrapNestedSalesRpcError(appError.serverMessage, stableCodes: _stableCodes);
  if (nested != null) return nested;
  return AppException('SYSTEM_ERROR', cause: error);
}
