import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Base fields for partner publish integration events.
abstract base class PartnerIntegrationEvent
    extends TenantScopedIntegrationEvent {
  const PartnerIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.eventType,
    required super.tenantId,
    required this.partnerId,
  });

  final String partnerId;

  @override
  Map<String, dynamic> toPayload() {
    return <String, dynamic>{
      'id': id,
      'occurred_on': occurredOn.toUtc().toIso8601String(),
      'tenant_id': tenantId,
      'partner_id': partnerId,
      'event_type': eventType,
    };
  }
}
