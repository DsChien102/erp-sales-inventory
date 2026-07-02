import 'package:vet45_partner_integration_events/integration_events.dart';
import 'package:vet45_shared_application/application.dart';

import '../partner_integration_event_dispatcher.dart';
import 'i_partner_inbox_client.dart';
import 'process_inbox_command.dart';

/// Claims inbox rows, deserializes to typed events, and dispatches to
/// application consumer handlers. Runs inside the `CommandBus` pipeline.
final class ProcessInboxCommandHandler
    implements ICommandHandler<ProcessInboxCommand, bool> {
  ProcessInboxCommandHandler({
    required IPartnerInboxClient inboxClient,
    required PartnerIntegrationEventDispatcher integrationEventDispatcher,
  })  : _inboxClient = inboxClient,
        _integrationEventDispatcher = integrationEventDispatcher;

  final IPartnerInboxClient _inboxClient;
  final PartnerIntegrationEventDispatcher _integrationEventDispatcher;

  @override
  Future<bool> handle(ProcessInboxCommand command) async {
    final messages = await _inboxClient.claimBatch(
      tenantId: command.tenantId,
      batchSize: command.batchSize,
    );
    if (messages.isEmpty) {
      return false;
    }

    for (final message in messages) {
      final event = PartnerIntegrationEventRegistry.fromInbox(
        eventType: message.eventType,
        messageId: message.messageId,
        occurredOn: message.occurredOn,
        payload: message.payload,
      );

      if (event == null) {
        await _inboxClient.fail(
          tenantId: command.tenantId,
          messageId: message.messageId,
          claimToken: message.claimToken,
          error: 'Unsupported partner inbox event: ${message.eventType}',
        );
        continue;
      }

      try {
        await _integrationEventDispatcher.publish(event);
        await _inboxClient.complete(
          tenantId: command.tenantId,
          messageId: message.messageId,
          claimToken: message.claimToken,
        );
      } catch (error) {
        await _inboxClient.fail(
          tenantId: command.tenantId,
          messageId: message.messageId,
          claimToken: message.claimToken,
          error: error.toString(),
        );
        rethrow;
      }
    }

    return true;
  }
}
