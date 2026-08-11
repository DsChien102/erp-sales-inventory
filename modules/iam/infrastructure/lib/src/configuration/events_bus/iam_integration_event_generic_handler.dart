import 'package:vet45_shared_infrastructure/infrastructure.dart';

import '../processing/inbox/i_iam_inbox_client.dart';

/// Writes inbound integration events into the IAM inbox (self-consume).
final class IamIntegrationEventGenericHandler<
  T extends TenantScopedIntegrationEvent
>
    implements IIntegrationEventHandler<T> {
  IamIntegrationEventGenericHandler({required IIamInboxClient inboxClient})
    : _inboxClient = inboxClient;

  final IIamInboxClient _inboxClient;

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
