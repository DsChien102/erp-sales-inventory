import 'package:vet45_shared_application/application.dart';
import 'package:vet45_shared_infrastructure/infrastructure.dart';

import 'i_sales_outbox_client.dart';
import 'process_outbox_command.dart';
import 'sales_outbox_event_serializer.dart';

/// Claims Sales outbox rows, publishes on [IEventsBus], then complete/fail.
final class ProcessOutboxCommandHandler implements ICommandHandler<ProcessOutboxCommand, bool> {
  ProcessOutboxCommandHandler({
    required ISalesOutboxClient outboxClient,
    required IEventsBus eventsBus,
  }) : _outboxClient = outboxClient,
       _eventsBus = eventsBus;

  final ISalesOutboxClient _outboxClient;
  final IEventsBus _eventsBus;

  @override
  Future<bool> handle(ProcessOutboxCommand command) async {
    final messages = await _outboxClient.claimBatch(
      tenantId: command.tenantId,
      limit: command.batchSize,
    );
    final hadWork = messages.isNotEmpty;

    for (final message in messages) {
      try {
        final event = SalesOutboxEventSerializer.fromMessage(
          tenantId: command.tenantId,
          message: message,
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
