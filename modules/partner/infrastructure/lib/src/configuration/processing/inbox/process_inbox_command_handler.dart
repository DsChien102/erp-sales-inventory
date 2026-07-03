import 'package:vet45_partner_integration_events/integration_events.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

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
    ILogger? logger,
  })  : _inboxClient = inboxClient,
        _integrationEventDispatcher = integrationEventDispatcher,
        _logger = logger;

  final IPartnerInboxClient _inboxClient;
  final PartnerIntegrationEventDispatcher _integrationEventDispatcher;
  final ILogger? _logger;

  @override
  Future<bool> handle(ProcessInboxCommand command) async {
    final messages = await _inboxClient.claimBatch(
      tenantId: command.tenantId,
      batchSize: command.batchSize,
    );
    if (messages.isEmpty) {
      _logger?.fine('Inbox idle tenant=${command.tenantId}');
      return false;
    }

    _logger?.info(
      'Processing inbox tenant=${command.tenantId} count=${messages.length}',
    );

    for (final message in messages) {
      final event = PartnerIntegrationEventRegistry.fromInbox(
        eventType: message.eventType,
        messageId: message.messageId,
        occurredOn: message.occurredOn,
        payload: message.payload,
      );

      if (event == null) {
        _logger?.warning(
          'Unsupported inbox event tenant=${command.tenantId} '
          'messageId=${message.messageId} type=${message.eventType}',
        );
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
        _logger?.info(
          'Inbox complete tenant=${command.tenantId} '
          'messageId=${message.messageId} type=${message.eventType}',
        );
      } catch (error, stackTrace) {
        _logger?.severe(
          'Inbox failed tenant=${command.tenantId} '
          'messageId=${message.messageId} type=${message.eventType}',
          error,
          stackTrace,
        );
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
