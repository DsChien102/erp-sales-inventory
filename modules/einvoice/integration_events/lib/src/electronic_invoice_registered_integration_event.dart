import 'einvoice_integration_event.dart';

/// Published when an electronic invoice is registered locally.
final class ElectronicInvoiceRegisteredIntegrationEvent
    extends EInvoiceIntegrationEvent {
  const ElectronicInvoiceRegisteredIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.electronicInvoiceId,
    required this.salesOrderId,
  }) : super(eventType: type);

  static const String type = 'einvoice.electronic_invoice.registered';

  final String electronicInvoiceId;
  final String salesOrderId;

  @override
  Map<String, dynamic> toPayload() => envelopePayload(<String, dynamic>{
        'electronic_invoice_id': electronicInvoiceId,
        'sales_order_id': salesOrderId,
      });
}
