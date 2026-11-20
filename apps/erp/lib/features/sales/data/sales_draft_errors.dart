import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_rpc_errors.dart';

abstract final class SalesDraftErrorCodes {
  static const noPermission = 'NO_PERMISSION'; // server PERMISSION_DENIED
  static const dataScopeDenied = 'DATA_SCOPE_DENIED';
  static const contextInvalid = 'CONTEXT_INVALID';
  static const referenceUnavailable = 'REFERENCE_UNAVAILABLE';
  static const staleData = 'STALE_DATA';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const systemError = 'SYSTEM_ERROR';
}

const Set<String> _stableCodes = {
  SalesDraftErrorCodes.noPermission,
  SalesDraftErrorCodes.dataScopeDenied,
  SalesDraftErrorCodes.contextInvalid,
  SalesDraftErrorCodes.referenceUnavailable,
  SalesDraftErrorCodes.staleData,
  SalesDraftErrorCodes.idempotencyConflict,
};

/// Q7: AppException có mã trong 6 mã ổn định → giữ code, serverMessage, details;
/// còn lại → SYSTEM_ERROR (cause = lỗi gốc).
AppException salesDraftException(Object error) {
  final appError = error is AppException ? error : AppException.from(error);
  if (_stableCodes.contains(appError.code)) {
    return appError;
  }
  final nested = unwrapNestedSalesRpcError(appError.serverMessage, stableCodes: _stableCodes);
  if (nested != null) return nested;
  return AppException(SalesDraftErrorCodes.systemError, cause: error);
}
