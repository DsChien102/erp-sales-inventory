import '../../../core/errors/app_exception.dart';

abstract final class PricingErrorCodes {
  static const noPermission = 'NO_PERMISSION';
  static const notFound = 'NOT_FOUND';
  static const validationError = 'VALIDATION_ERROR';
  static const overwriteRequired = 'OVERWRITE_REQUIRED';
  static const duplicateActiveRule = 'DUPLICATE_ACTIVE_RULE';
  static const belowFloorBlocked = 'BELOW_FLOOR_BLOCKED';
  static const referenceInvalid = 'REFERENCE_INVALID';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const stateChanged = 'STATE_CHANGED';
  static const invalidStatus = 'INVALID_STATUS';
  static const systemError = 'SYSTEM_ERROR';
}

const Set<String> _stableCodes = {
  PricingErrorCodes.noPermission,
  PricingErrorCodes.notFound,
  PricingErrorCodes.validationError,
  PricingErrorCodes.duplicateActiveRule,
  PricingErrorCodes.belowFloorBlocked,
  PricingErrorCodes.referenceInvalid,
  PricingErrorCodes.idempotencyConflict,
  PricingErrorCodes.stateChanged,
  PricingErrorCodes.invalidStatus,
  PricingErrorCodes.systemError,
};

/// Q7: giữ cách của mapPricingRpcError. AppException có mã trong 10 mã ổn định
/// (_stableCode) → giữ nguyên code, serverMessage, details; còn lại → SYSTEM_ERROR (cause = error gốc).
AppException pricingException(Object error) {
  final appError = error is AppException ? error : AppException.from(error);
  if (_stableCodes.contains(appError.code)) {
    return appError;
  }
  return AppException(PricingErrorCodes.systemError, cause: error);
}

