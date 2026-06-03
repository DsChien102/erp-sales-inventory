import 'integration_event.dart';
import 'integration_event_json.dart';

/// Base class for tenant-scoped integration event contracts across ERP modules.
abstract class TenantScopedIntegrationEvent extends IntegrationEvent {
  const TenantScopedIntegrationEvent({
    required super.id,
    required super.occurredOn,
    required super.eventType,
    required this.tenantId,
  });

  final String tenantId;

  Map<String, dynamic> toPayload();

  static String resolveId(Map<String, dynamic> json) => integrationEventIdFromMap(json);
}
