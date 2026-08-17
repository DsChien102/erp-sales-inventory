import 'einvoice_integration_event.dart';

/// Published when delivery result is recorded or updated.
final class DeliveryResultRecordedIntegrationEvent
    extends EInvoiceIntegrationEvent {
  const DeliveryResultRecordedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.salesOrderId,
    required this.deliveryId,
  }) : super(eventType: type);

  static const String type = 'einvoice.delivery.result_recorded';

  final String salesOrderId;
  final String deliveryId;
}
