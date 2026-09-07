import 'einvoice_integration_event.dart';

/// Published when an electronic invoice is registered locally.
final class ElectronicInvoiceRegisteredIntegrationEvent extends EInvoiceIntegrationEvent {
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

  factory ElectronicInvoiceRegisteredIntegrationEvent.fromPayload(
    Map<String, dynamic> payload,
  ) {
    return ElectronicInvoiceRegisteredIntegrationEvent(
      id: _requiredString(payload, 'id'),
      occurredOn: _requiredDateTime(payload, 'occurred_on'),
      tenantId: _requiredString(payload, 'tenant_id'),
      electronicInvoiceId: _requiredString(payload, 'electronic_invoice_id'),
      salesOrderId: _requiredString(payload, 'sales_order_id'),
    );
  }

  static String _requiredString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing or empty $key');
    }
    return value.trim();
  }

  static DateTime _requiredDateTime(Map<String, dynamic> payload, String key) {
    final raw = _requiredString(payload, key);
    try {
      return DateTime.parse(raw).toUtc();
    } on FormatException {
      throw FormatException('Malformed $key timestamp');
    }
  }
}
