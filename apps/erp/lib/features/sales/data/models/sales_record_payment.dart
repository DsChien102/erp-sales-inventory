import 'package:erp/features/sales/data/models.dart';

final class SalesRecordPaymentRequest {
  const SalesRecordPaymentRequest({
    required this.storeId,
    required this.salesOrderId,
    required this.amountMinor,
    required this.method,
    this.externalReference,
    required this.idempotencyKey,
    required this.payloadHash,
    required this.correlationId,
  });

  final String storeId;
  final String salesOrderId;
  final int amountMinor;
  final SalesPaymentMethod method;
  final String? externalReference;
  final String idempotencyKey;
  final String payloadHash;
  final String correlationId;
}

final class SalesRecordPaymentResult {
  const SalesRecordPaymentResult({
    required this.transactionId,
    required this.outstandingMinor,
    required this.paymentStatus,
    required this.version,
  });

  final String transactionId;
  final int outstandingMinor;
  final String paymentStatus;
  final int version;
}

