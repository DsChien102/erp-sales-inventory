import 'einvoice_integration_event.dart';

/// Published when delivery reconciliation reaches UNRESOLVED.
///
/// Payload carries ids and a Vet45-authored safe error code only —
/// never recipient email, provider body, headers, or raw exception text.
final class DeliveryAttentionRequiredIntegrationEvent extends EInvoiceIntegrationEvent {
  const DeliveryAttentionRequiredIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.electronicInvoiceId,
    required this.salesOrderId,
    required this.deliveryId,
    required this.reconciliationCaseId,
    required this.safeErrorCode,
  }) : super(eventType: type);

  static const String type = 'einvoice.delivery.attention_required';

  final String electronicInvoiceId;
  final String salesOrderId;
  final String deliveryId;
  final String reconciliationCaseId;
  final String safeErrorCode;

  @override
  Map<String, dynamic> toPayload() => envelopePayload(<String, dynamic>{
    'electronic_invoice_id': electronicInvoiceId,
    'sales_order_id': salesOrderId,
    'delivery_id': deliveryId,
    'reconciliation_case_id': reconciliationCaseId,
    'safe_error_code': safeErrorCode,
  });

  factory DeliveryAttentionRequiredIntegrationEvent.fromPayload(
    Map<String, dynamic> payload,
  ) {
    return DeliveryAttentionRequiredIntegrationEvent(
      id: _requiredString(payload, 'id'),
      occurredOn: _requiredDateTime(payload, 'occurred_on'),
      tenantId: _requiredString(payload, 'tenant_id'),
      electronicInvoiceId: _requiredString(payload, 'electronic_invoice_id'),
      salesOrderId: _requiredString(payload, 'sales_order_id'),
      deliveryId: _requiredString(payload, 'delivery_id'),
      reconciliationCaseId: _requiredString(payload, 'reconciliation_case_id'),
      safeErrorCode: _requiredString(payload, 'safe_error_code'),
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
