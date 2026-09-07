import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../processing/inbox/i_einvoice_inbox_client.dart';

/// Writes inbound integration events into the einvoice inbox (self-consume).
final class EinvoiceIntegrationEventGenericHandler<
  T extends TenantScopedIntegrationEvent
>
    implements IIntegrationEventHandler<T> {
  EinvoiceIntegrationEventGenericHandler({
    required IEinvoiceInboxClient inboxClient,
  }) : _inboxClient = inboxClient;

  final IEinvoiceInboxClient _inboxClient;

  @override
  Future<void> handle(T event) async {
    await _inboxClient.receive(
      tenantId: event.tenantId,
      messageId: event.id,
      eventType: event.eventType,
      payload: event.toPayload(),
      occurredAt: event.occurredOn,
    );
  }
}
