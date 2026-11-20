import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/sales_cancellation_request.dart';
import 'package:uuid/uuid.dart';

/// An immutable cancellation submit attempt. Retrying the same payload must
/// reuse the same command id, idempotency key and payload hash; any change to
/// reason/note/version produces a new attempt.
final class SalesOrderCancellationAttempt {
  const SalesOrderCancellationAttempt({
    required this.request,
    required this.canonicalPayloadJson,
    required this.payloadHash,
  });

  final SalesOrderCancellationRequest request;
  final String canonicalPayloadJson;
  final String payloadHash;
}

final class SalesOrderCancellationAttemptFactory {
  SalesOrderCancellationAttemptFactory({String Function()? newAttemptId})
    : _newAttemptId = newAttemptId ?? const Uuid().v4;

  final String Function() _newAttemptId;

  SalesOrderCancellationAttempt create({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required int expectedOrderVersion,
    required int expectedSettlementVersion,
    required String? reasonText,
    required String correlationId,
  }) {
    final trimmedTenantId = tenantId.trim();
    final trimmedActorId = actorId.trim();
    final trimmedSalesOrderId = salesOrderId.trim();
    final trimmedCorrelationId = correlationId.trim();
    if (trimmedTenantId.isEmpty ||
        trimmedActorId.isEmpty ||
        trimmedSalesOrderId.isEmpty ||
        trimmedCorrelationId.isEmpty ||
        expectedOrderVersion <= 0 ||
        expectedSettlementVersion <= 0) {
      throw const AppException('CONTEXT_INVALID');
    }

    // Blank note maps to "" to match the existing command/RPC contract.
    final normalizedReasonText = (reasonText ?? '').trim();

    final payload = <String, Object?>{
      'expectedOrderVersion': expectedOrderVersion,
      'expectedSettlementVersion': expectedSettlementVersion,
      'reasonText': normalizedReasonText,
      'salesOrderId': trimmedSalesOrderId,
      'tenantId': trimmedTenantId,
    };
    final canonicalJson = jsonEncode(_sort(payload));
    final payloadHash = sha256.convert(utf8.encode(canonicalJson)).toString();
    final attemptId = _newAttemptId();
    final request = SalesOrderCancellationRequest(
      commandId: attemptId,
      salesOrderId: trimmedSalesOrderId,
      reasonText: normalizedReasonText,
      idempotencyKey: 'sales-order-cancellation:$attemptId',
      payloadHash: payloadHash,
      correlationId: trimmedCorrelationId,
      expectedOrderVersion: expectedOrderVersion,
      expectedSettlementVersion: expectedSettlementVersion,
    );
    return SalesOrderCancellationAttempt(
      request: request,
      canonicalPayloadJson: canonicalJson,
      payloadHash: payloadHash,
    );
  }

  static Object? _sort(Object? value) {
    if (value is Map<String, Object?>) {
      final keys = value.keys.toList()..sort();
      return <String, Object?>{for (final key in keys) key: _sort(value[key])};
    }
    if (value is List) return [for (final item in value) _sort(item)];
    return value;
  }
}
