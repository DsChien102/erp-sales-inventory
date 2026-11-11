import 'dart:async';

import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/sales_rpc_errors.dart';

abstract final class SalesCheckoutErrorCodes {
  static const noPermission = 'NO_PERMISSION'; // server PERMISSION_DENIED
  static const checkoutBlocked = 'CHECKOUT_BLOCKED';
  static const staleVersion = 'STALE_VERSION';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const dependencyUnavailable = 'DEPENDENCY_UNAVAILABLE';
  static const uncertainResult = 'UNCERTAIN_RESULT';
  static const productNotSellable = 'PRODUCT_NOT_SELLABLE';
  static const dataScopeDenied = 'DATA_SCOPE_DENIED';
  static const contextInvalid = 'CONTEXT_INVALID';
  static const checkoutResultNotFound = 'CHECKOUT_RESULT_NOT_FOUND';
  static const priceChanged = 'PRICE_CHANGED';
  static const pricingBlocked = 'PRICING_BLOCKED';
  static const insufficientStock = 'INSUFFICIENT_STOCK';
  static const networkError = 'NETWORK_ERROR'; // AppErrorCode.network
  static const systemError = 'SYSTEM_ERROR';
}

const Set<String> _stableCodes = {
  SalesCheckoutErrorCodes.noPermission,
  SalesCheckoutErrorCodes.checkoutBlocked,
  SalesCheckoutErrorCodes.staleVersion,
  SalesCheckoutErrorCodes.idempotencyConflict,
  SalesCheckoutErrorCodes.dependencyUnavailable,
  SalesCheckoutErrorCodes.uncertainResult,
  SalesCheckoutErrorCodes.productNotSellable,
  SalesCheckoutErrorCodes.dataScopeDenied,
  SalesCheckoutErrorCodes.contextInvalid,
  SalesCheckoutErrorCodes.checkoutResultNotFound,
  SalesCheckoutErrorCodes.priceChanged,
  SalesCheckoutErrorCodes.pricingBlocked,
  SalesCheckoutErrorCodes.insufficientStock,
  SalesCheckoutErrorCodes.networkError,
};

/// Q5/Q6: mã trong 12 mã ổn định + NETWORK_ERROR → giữ; còn lại SYSTEM_ERROR.
/// [uncertainOnNetwork] (chỉ finalize): mất mạng / timeout → UNCERTAIN_RESULT.
AppException salesCheckoutException(Object error, {bool uncertainOnNetwork = false}) {
  if (uncertainOnNetwork && error is TimeoutException) {
    return AppException(SalesCheckoutErrorCodes.uncertainResult, cause: error);
  }
  final appError = error is AppException ? error : AppException.from(error);
  if (uncertainOnNetwork && appError.code == SalesCheckoutErrorCodes.networkError) {
    return AppException(
      SalesCheckoutErrorCodes.uncertainResult,
      serverMessage: appError.serverMessage,
      cause: error,
    );
  }
  if (_stableCodes.contains(appError.code)) return appError;
  final nested = unwrapNestedSalesRpcError(appError.serverMessage, stableCodes: _stableCodes);
  if (nested != null) {
    if (uncertainOnNetwork && nested.code == SalesCheckoutErrorCodes.networkError) {
      return AppException(SalesCheckoutErrorCodes.uncertainResult, cause: error);
    }
    return nested;
  }
  return AppException(SalesCheckoutErrorCodes.systemError, cause: error);
}
