import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:erp/core/errors/app_exception.dart';
import 'package:erp/features/sales/data/models/sales_record_payment.dart';
import 'package:uuid/uuid.dart';
import 'package:vet45_sales_application/application.dart';

final class SalesRecordPaymentAttempt {
  const SalesRecordPaymentAttempt({
    required this.request,
    required this.canonicalPayloadJson,
    required this.payloadHash,
  });

  final SalesRecordPaymentRequest request;
  final String canonicalPayloadJson;
  final String payloadHash;
}

final class SalesRecordPaymentAttemptFactory {
  SalesRecordPaymentAttemptFactory({String Function()? newAttemptId})
    : _newAttemptId = newAttemptId ?? const Uuid().v4;

  final String Function() _newAttemptId;

  SalesRecordPaymentAttempt create({
    required String tenantId,
    required String actorId,
    required String storeId,
    required String salesOrderId,
    required int amountMinor,
    required SalesPaymentMethod method,
    String? externalReference,
    required String correlationId,
  }) {
    final trimmedTenantId = tenantId.trim();
    final trimmedActorId = actorId.trim();
    final trimmedStoreId = storeId.trim();
    final trimmedSalesOrderId = salesOrderId.trim();
    final trimmedCorrelationId = correlationId.trim();

    if (trimmedTenantId.isEmpty ||
        trimmedActorId.isEmpty ||
        trimmedStoreId.isEmpty ||
        trimmedSalesOrderId.isEmpty ||
        trimmedCorrelationId.isEmpty ||
        amountMinor <= 0) {
      throw const AppException('CONTEXT_INVALID');
    }

    final normalizedReference =
        (externalReference == null || externalReference.trim().isEmpty)
            ? null
            : externalReference.trim();

    final payload = <String, Object?>{
      'actorId': trimmedActorId,
      'amountMinor': amountMinor,
      'externalReference': normalizedReference,
      'method': method.name,
      'salesOrderId': trimmedSalesOrderId,
      'storeId': trimmedStoreId,
      'tenantId': trimmedTenantId,
    };

    final canonicalJson = jsonEncode(_sort(payload));
    final payloadHash = sha256.convert(utf8.encode(canonicalJson)).toString();
    final attemptId = _newAttemptId();

    final request = SalesRecordPaymentRequest(
      storeId: trimmedStoreId,
      salesOrderId: trimmedSalesOrderId,
      amountMinor: amountMinor,
      method: method,
      externalReference: normalizedReference,
      idempotencyKey: 'sales-payment:$attemptId',
      payloadHash: payloadHash,
      correlationId: trimmedCorrelationId,
    );

    return SalesRecordPaymentAttempt(
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

