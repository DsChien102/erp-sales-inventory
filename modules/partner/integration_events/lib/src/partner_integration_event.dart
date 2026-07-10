import 'package:vet45_shared_infrastructure/infrastructure.dart';

/// Base fields for partner publish integration events.
abstract base class PartnerIntegrationEvent extends IntegrationEvent {
  const PartnerIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.eventType,
    required this.tenantId,
    required this.partnerId,
  });

  final String tenantId;
  final String partnerId;
}
