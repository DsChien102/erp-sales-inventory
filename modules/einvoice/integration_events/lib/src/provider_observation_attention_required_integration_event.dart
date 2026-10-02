import 'einvoice_integration_event.dart';

/// Published when provider observation requires operational attention.
final class ProviderObservationAttentionRequiredIntegrationEvent extends EInvoiceIntegrationEvent {
  const ProviderObservationAttentionRequiredIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.tenantId,
    required this.observationId,
    required this.electronicInvoiceId,
    required this.providerStateCode,
    required this.correlationId,
  }) : super(eventType: type);

  static const String type = 'einvoice.provider_observation_attention_required';

  final String observationId;
  final String electronicInvoiceId;
  final String providerStateCode;
  final String correlationId;

  @override
  Map<String, dynamic> toPayload() => envelopePayload(<String, dynamic>{
    'observation_id': observationId,
    'electronic_invoice_id': electronicInvoiceId,
    'provider_state_code': providerStateCode,
    'correlation_id': correlationId,
  });

  factory ProviderObservationAttentionRequiredIntegrationEvent.fromPayload(
    Map<String, dynamic> payload,
  ) {
    final observationId = _requiredString(payload, 'observation_id');
    final electronicInvoiceId = _requiredString(
      payload,
      'electronic_invoice_id',
    );
    final providerStateCode = _requiredString(payload, 'provider_state_code');
    final correlationId = _requiredString(payload, 'correlation_id');

    return ProviderObservationAttentionRequiredIntegrationEvent(
      id: _requiredString(payload, 'id'),
      occurredOn: DateTime.parse(_requiredString(payload, 'occurred_on')),
      tenantId: _requiredString(payload, 'tenant_id'),
      observationId: observationId,
      electronicInvoiceId: electronicInvoiceId,
      providerStateCode: providerStateCode,
      correlationId: correlationId,
    );
  }

  static String _requiredString(Map<String, dynamic> payload, String key) {
    final value = payload[key];
    if (value is! String || value.trim().isEmpty) {
      throw FormatException('Missing or empty $key');
    }
    return value.trim();
  }
}
