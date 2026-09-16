import 'package:vet45_sales_integration_events/integration_events.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'i_sales_outbox_client.dart';
import 'unrouted_sales_fact_integration_event.dart';

/// Maps claimed Sales outbox rows to typed facts or opaque unrouted facts.
abstract final class SalesOutboxEventSerializer {
  static TenantScopedIntegrationEvent fromMessage({
    required String tenantId,
    required ClaimedSalesOutboxMessage message,
  }) {
    final payload = Map<String, dynamic>.from(message.payload)
      ..putIfAbsent('id', () => message.messageId)
      ..putIfAbsent('tenant_id', () => tenantId)
      ..putIfAbsent(
        'occurred_on',
        () => message.occurredAt.toUtc().toIso8601String(),
      );
    if (message.eventType == SalesOrderFinalizedIntegrationEvent.type) {
      return SalesOrderFinalizedIntegrationEvent.fromPayload(payload);
    }
    return UnroutedSalesFactIntegrationEvent(
      id: message.messageId,
      occurredOn: message.occurredAt,
      tenantId: tenantId,
      eventType: message.eventType,
      payload: payload,
    );
  }
}
