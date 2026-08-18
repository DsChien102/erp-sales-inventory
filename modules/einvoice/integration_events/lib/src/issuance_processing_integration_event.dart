import 'einvoice_integration_event.dart';

/// Published when an issuance attempt is in progress.
final class IssuanceProcessingIntegrationEvent extends EInvoiceIntegrationEvent {
  const IssuanceProcessingIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.salesOrderId,
    required this.attemptId,
  }) : super(eventType: type);

  static const String type = 'einvoice.issuance.processing';

  final String salesOrderId;
  final String attemptId;

  @override
  Map<String, dynamic> toPayload() => envelopePayload(<String, dynamic>{
        'sales_order_id': salesOrderId,
        'attempt_id': attemptId,
      });
}
