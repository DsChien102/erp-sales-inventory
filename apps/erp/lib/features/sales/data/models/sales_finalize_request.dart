import 'package:erp/features/sales/data/models.dart';

/// Thay FinalizeSalesOrderCommand trong app (không chứa tenantId / actorId).
final class SalesFinalizeRequest {
  SalesFinalizeRequest({
    required this.commandId,
    required this.storeId,
    this.sourceDraftId,
    this.customerId,
    required this.currencyCode,
    this.orderNote,
    this.paymentDueDate,
    required List<CheckoutLineInput> lines,
    required List<PaymentIntentInput> paymentIntents,
    required this.commercialSnapshot,
    required this.idempotencyKey,
    required this.payloadHash,
    required this.correlationId,
    this.expectedSourceVersion,
  }) : lines = List.unmodifiable(lines),
       paymentIntents = List.unmodifiable(paymentIntents);

  final String commandId;
  final String storeId;
  final String? sourceDraftId;
  final String? customerId;
  final String currencyCode;
  final String? orderNote;

  /// Ngày (không giờ).
  final DateTime? paymentDueDate;
  final List<CheckoutLineInput> lines;
  final List<PaymentIntentInput> paymentIntents;
  final SalesCommercialSnapshotInput commercialSnapshot;
  final String idempotencyKey;
  final String payloadHash;
  final String correlationId;
  final int? expectedSourceVersion;
}
