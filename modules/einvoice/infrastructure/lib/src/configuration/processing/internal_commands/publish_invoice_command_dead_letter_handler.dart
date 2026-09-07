import 'package:vet45_einvoice_application/application.dart';

import 'i_einvoice_internal_command_client.dart';
import 'i_einvoice_internal_command_dead_letter_handler.dart';

final class PublishInvoiceCommandDeadLetterHandler
    implements IEinvoiceInternalCommandDeadLetterHandler {
  const PublishInvoiceCommandDeadLetterHandler({
    required IIssuanceResultGateway resultGateway,
  }) : _resultGateway = resultGateway;

  final IIssuanceResultGateway _resultGateway;

  @override
  Future<void> handleDeadLetter({
    required String tenantId,
    required ClaimedInternalCommand command,
    required Object error,
  }) async {
    if (error is CanonicalInvoiceIntegrityException) {
      await _resultGateway.recordCommandIntegrityFailure(
        tenantId: tenantId,
        attemptId: error.attemptId,
        reasonCode: error.reasonCode,
      );
      return;
    }

    final attemptId =
        command.payload['attempt_id']?.toString() ??
        (throw ArgumentError(
          'PublishInvoiceCommand payload missing attempt_id',
        ));

    await _resultGateway.recordPublishCommandDeadLetter(
      tenantId: tenantId,
      attemptId: attemptId,
      reasonCode: error.toString(),
    );
  }
}
