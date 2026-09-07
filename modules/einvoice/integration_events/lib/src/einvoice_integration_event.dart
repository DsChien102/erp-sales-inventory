import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Base fields for einvoice publish integration events.
abstract base class EInvoiceIntegrationEvent extends TenantScopedIntegrationEvent {
  const EInvoiceIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.eventType,
    required super.tenantId,
  });

  /// Common envelope fields for outbox persistence.
  Map<String, dynamic> envelopePayload(Map<String, dynamic> fields) {
    return <String, dynamic>{
      'id': id,
      'occurred_on': occurredOn.toUtc().toIso8601String(),
      'tenant_id': tenantId,
      'event_type': eventType,
      ...fields,
    };
  }
}
