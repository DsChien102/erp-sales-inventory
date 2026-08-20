import 'package:vet45_shared_application/application.dart';

import '../generated/iam_integration_event_registry.g.dart';
import '../iam_integration_event_dispatcher.dart';
import 'i_iam_inbox_client.dart';
import 'process_inbox_command.dart';

final class ProcessInboxCommandHandler
    implements ICommandHandler<ProcessInboxCommand, bool> {
  ProcessInboxCommandHandler({
    required IIamInboxClient inboxClient,
    required IamIntegrationEventDispatcher integrationEventDispatcher,
  }) : _inboxClient = inboxClient,
       _integrationEventDispatcher = integrationEventDispatcher;

  final IIamInboxClient _inboxClient;
  final IamIntegrationEventDispatcher _integrationEventDispatcher;

  @override
  Future<bool> handle(ProcessInboxCommand command) async {
    final messages = await _inboxClient.claimBatch(
      tenantId: command.tenantId,
      limit: command.batchSize,
    );
    final hadWork = messages.isNotEmpty;

    for (final message in messages) {
      final payload = Map<String, dynamic>.from(message.payload);
      payload.putIfAbsent('tenant_id', () => command.tenantId);
      payload.putIfAbsent('id', () => message.messageId);
      payload.putIfAbsent(
        'occurred_on',
        () => message.occurredAt.toUtc().toIso8601String(),
      );

      final event = IamIntegrationEventRegistry.fromJson(
        eventType: message.eventType,
        payload: payload,
      );

      if (event == null) {
        await _inboxClient.fail(
          tenantId: command.tenantId,
          messageId: message.messageId,
          claimToken: message.claimToken,
          error: 'Unknown event type: ${message.eventType}',
        );
        continue;
      }

      if (event.id != message.messageId) {
        await _inboxClient.fail(
          tenantId: command.tenantId,
          messageId: message.messageId,
          claimToken: message.claimToken,
          error:
              'Inbox message id ${message.messageId} does not match '
              'event id ${event.id}',
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
      }
    }

    return hadWork;
  }
}
