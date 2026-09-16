import 'package:uuid/uuid.dart';

/// Utilities for generating canonical trigger keys and UUIDv5 idempotency keys for auto-issuance.
abstract final class AutoIssuanceIdempotencyKey {
  static const String namespace = '6ba7b811-9dad-11d1-80b4-00c04fd430c8';

  /// Generates the canonical trigger key for a Sales finalized integration event.
  static String triggerKey({
    required String eventType,
    required String eventId,
    required String salesOrderId,
    required String sourceVersion,
  }) {
    return '$eventType:$eventId:$salesOrderId:$sourceVersion';
  }

  /// Generates a deterministic canonical UUIDv5 for automatic issuance idempotency.
  static String generate({
    required String tenantId,
    required String salesOrderId,
    required String sourceVersion,
  }) {
    final seed = 'einvoice:auto_issue:$tenantId:$salesOrderId:$sourceVersion';
    return const Uuid().v5(namespace, seed);
  }
}
