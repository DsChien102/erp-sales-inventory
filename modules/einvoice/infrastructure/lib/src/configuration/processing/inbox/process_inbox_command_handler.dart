import 'package:vet45_shared_application/application.dart';

import 'i_einvoice_inbox_client.dart';
import 'process_inbox_command.dart';

/// Claims inbox rows — S1 has no subscribed integration events yet.
final class ProcessInboxCommandHandler
    implements ICommandHandler<ProcessInboxCommand, bool> {
  ProcessInboxCommandHandler({required IEinvoiceInboxClient inboxClient})
    : _inboxClient = inboxClient;

  final IEinvoiceInboxClient _inboxClient;

  @override
  Future<bool> handle(ProcessInboxCommand command) async {
    final messages = await _inboxClient.claimBatch(
      tenantId: command.tenantId,
      limit: command.batchSize,
    );
    final hadWork = messages.isNotEmpty;

    for (final message in messages) {
      await _inboxClient.fail(
        tenantId: command.tenantId,
        messageId: message.messageId,
        claimToken: message.claimToken,
        error: 'Unhandled inbox event type: ${message.eventType}',
      );
    }

    return hadWork;
  }
}
