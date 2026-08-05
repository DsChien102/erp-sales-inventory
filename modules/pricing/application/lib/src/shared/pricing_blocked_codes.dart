abstract final class PricingBlockedCodes {
  static const noPermission = 'NO_PERMISSION';
  static const notFound = 'NOT_FOUND';
  static const validationError = 'VALIDATION_ERROR';

  /// SSOT: active interval overlaps another active rule for the same key.
  static const overwriteRequired = 'OVERWRITE_REQUIRED';

  /// @deprecated — legacy blocked duplicate. Map to [overwriteRequired] in catch-up slice.
  static const duplicateActiveRule = 'DUPLICATE_ACTIVE_RULE';

  static const belowFloorBlocked = 'BELOW_FLOOR_BLOCKED';
  static const referenceInvalid = 'REFERENCE_INVALID';
  static const idempotencyConflict = 'IDEMPOTENCY_CONFLICT';
  static const stateChanged = 'STATE_CHANGED';
  static const invalidStatus = 'INVALID_STATUS';
  static const systemError = 'SYSTEM_ERROR';
}
