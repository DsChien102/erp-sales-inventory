import 'dart:convert';

import 'package:vet45_pricing_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

PricingBlockedException mapPricingRpcError(RpcException error) {
  final envelope = _decodeEnvelope(error.message);
  if (envelope == null) {
    return PricingBlockedException(
      PricingBlockedCodes.systemError,
      message: 'Pricing operation failed.',
    );
  }
  final code = _stableCode(envelope['code']);
  final message = envelope['message'];
  final details = _safeDetails(envelope['details']);
  if (code == PricingBlockedCodes.systemError ||
      (message != null && message is! String) ||
      details == null) {
    return const PricingBlockedException(
      PricingBlockedCodes.systemError,
      message: 'Pricing operation failed.',
    );
  }
  return PricingBlockedException(
    code,
    message: message as String?,
    details: details,
  );
}

Map<String, Object?>? _safeDetails(Object? value) {
  if (value == null) return const {};
  if (value is! Map) return null;
  final result = <String, Object?>{};
  for (final entry in value.entries) {
    if (entry.key is! String) return null;
    result[entry.key as String] = entry.value;
  }
  return result;
}

String _stableCode(Object? value) => switch (value) {
  PricingBlockedCodes.noPermission => PricingBlockedCodes.noPermission,
  PricingBlockedCodes.notFound => PricingBlockedCodes.notFound,
  PricingBlockedCodes.validationError => PricingBlockedCodes.validationError,
  PricingBlockedCodes.duplicateActiveRule =>
    PricingBlockedCodes.duplicateActiveRule,
  PricingBlockedCodes.belowFloorBlocked =>
    PricingBlockedCodes.belowFloorBlocked,
  PricingBlockedCodes.referenceInvalid => PricingBlockedCodes.referenceInvalid,
  PricingBlockedCodes.idempotencyConflict =>
    PricingBlockedCodes.idempotencyConflict,
  PricingBlockedCodes.stateChanged => PricingBlockedCodes.stateChanged,
  PricingBlockedCodes.invalidStatus => PricingBlockedCodes.invalidStatus,
  PricingBlockedCodes.systemError => PricingBlockedCodes.systemError,
  _ => PricingBlockedCodes.systemError,
};

Map<String, dynamic>? _decodeEnvelope(String message) {
  final start = message.indexOf('{');
  final end = message.lastIndexOf('}');
  if (start < 0 || end <= start) return null;
  try {
    final decoded = jsonDecode(message.substring(start, end + 1));
    return decoded is Map ? decoded.cast<String, dynamic>() : null;
  } on FormatException {
    return null;
  }
}
