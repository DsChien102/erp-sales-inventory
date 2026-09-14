import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_sales_application/application.dart';

/// An immutable cancellation submit attempt. Retrying the same payload must
/// reuse the same command id, idempotency key and payload hash; any change to
/// reason/note/version produces a new attempt.
final class SalesOrderCancellationAttempt {
  const SalesOrderCancellationAttempt({
    required this.command,
    required this.canonicalPayloadJson,
    required this.payloadHash,
  });

  final ConfirmSalesOrderCancellationCommand command;
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
      throw const SalesContractException(
        'CONTEXT_INVALID',
        message: 'Cancellation attempt requires context and positive versions.',
      );
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
    final command = ConfirmSalesOrderCancellationCommand(
      id: attemptId,
      tenantId: trimmedTenantId,
      actorId: trimmedActorId,
      salesOrderId: trimmedSalesOrderId,
      reason: CancellationReasonDto(
        reasonText: normalizedReasonText,
      ),
      idempotencyKey: 'sales-order-cancellation:$attemptId',
      payloadHash: payloadHash,
      correlationId: trimmedCorrelationId,
      expectedVersion: expectedOrderVersion,
      expectedSettlementVersion: expectedSettlementVersion,
    );
    return SalesOrderCancellationAttempt(
      command: command,
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
