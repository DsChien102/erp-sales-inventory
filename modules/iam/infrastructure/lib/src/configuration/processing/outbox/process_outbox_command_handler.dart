import 'package:vet45_iam_integration_events/integration_events.dart';
import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'i_iam_outbox_client.dart';
import 'process_outbox_command.dart';

/// Claims outbox rows, maps to integration events, publishes on [IEventsBus].
final class ProcessOutboxCommandHandler
    implements ICommandHandler<ProcessOutboxCommand, bool> {
  ProcessOutboxCommandHandler({
    required IIamOutboxClient outboxClient,
    required IDomainNotificationMapper eventTypeMapper,
    required IEventsBus eventsBus,
  }) : _outboxClient = outboxClient,
       _eventTypeMapper = eventTypeMapper,
       _eventsBus = eventsBus;

  final IIamOutboxClient _outboxClient;
  final IDomainNotificationMapper _eventTypeMapper;
  final IEventsBus _eventsBus;

  @override
  Future<bool> handle(ProcessOutboxCommand command) async {
    final messages = await _outboxClient.claimBatch(
      tenantId: command.tenantId,
      limit: command.batchSize,
    );
    final hadWork = messages.isNotEmpty;

    for (final message in messages) {
      final eventDartType = _eventTypeMapper.getType(message.eventType);
      if (eventDartType == null) {
        await _outboxClient.fail(
          tenantId: command.tenantId,
          messageId: message.messageId,
          claimToken: message.claimToken,
          error: 'Unknown outbox event type: ${message.eventType}',
        );
        continue;
      }

      try {
        final payload = Map<String, dynamic>.from(message.payload);
        payload.putIfAbsent('id', () => message.messageId);
        payload.putIfAbsent('tenant_id', () => command.tenantId);
        payload.putIfAbsent(
          'occurred_on',
          () => message.occurredAt.toUtc().toIso8601String(),
        );

        final event = IamOutboxEventSerializer.fromPayload(
          type: eventDartType,
          payload: payload,
        );
        await _eventsBus.publish(event);
        await _outboxClient.complete(
          tenantId: command.tenantId,
          messageId: message.messageId,
          claimToken: message.claimToken,
        );
      } catch (error) {
        await _outboxClient.fail(
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

/// Deserializes outbox payloads into IAM integration events.
abstract final class IamOutboxEventSerializer {
  static TenantScopedIntegrationEvent fromPayload({
    required Type type,
    required Map<String, dynamic> payload,
  }) {
    if (type == EmailDeliveryRequestedIntegrationEvent) {
      return EmailDeliveryRequestedIntegrationEvent.fromPayload(payload);
    }
    throw StateError('Unsupported outbox event type: $type');
  }
}
