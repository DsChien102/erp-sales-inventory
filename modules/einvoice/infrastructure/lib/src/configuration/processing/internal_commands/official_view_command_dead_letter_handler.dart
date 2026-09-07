import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import 'i_einvoice_internal_command_client.dart';
import 'i_einvoice_internal_command_dead_letter_handler.dart';

final class OfficialViewCommandDeadLetterHandler
    implements IEinvoiceInternalCommandDeadLetterHandler {
  OfficialViewCommandDeadLetterHandler({
    required IElectronicInvoiceCommandGateway commandGateway,
    required IProviderInteractionGateway interactionGateway,
  }) : _commandGateway = commandGateway,
       _interactionGateway = interactionGateway;

  final IElectronicInvoiceCommandGateway _commandGateway;
  final IProviderInteractionGateway _interactionGateway;

  @override
  Future<void> handleDeadLetter({
    required String tenantId,
    required ClaimedInternalCommand command,
    required Object error,
  }) async {
    final operationId = command.payload['operation_id']?.toString();
    if (operationId == null || operationId.isEmpty) {
      return;
    }

    final context = await _commandGateway.loadOfficialViewContext(
      tenantId: tenantId,
      operationId: operationId,
    );
    if (context == null || context.status != InvoiceDocumentStatus.pending) {
      return;
    }

    final attemptNumber = command.retryCount + 1;
    final correlationId = ProviderCallCorrelationId.forWorkerAttempt(
      commandId: command.commandId,
      workerAttemptNumber: attemptNumber,
    );

    final interaction = await _interactionGateway.start(
      tenantId: tenantId,
      providerConnectionId: context.providerConnectionId,
      direction: ProviderInteractionDirection.outbound,
      operationType: FetchOfficialInvoiceViewCommand.type,
      targetType: 'OFFICIAL_VIEW_OPERATION',
      targetId: operationId,
      correlationId: correlationId,
      requestReference: command.commandId,
    );

    await _commandGateway.recordOfficialViewResult(
      OfficialViewResultRecord(
        tenantId: tenantId,
        operationId: context.operationId,
        status: InvoiceDocumentStatus.checkRequired,
        failureCode: 'PROVIDER_RESULT_UNDETERMINED',
        failureMessage: error.toString(),
        providerInteractionReference: interaction.interactionReference,
        expectedVersion: context.expectedVersion,
      ),
    );
  }
}
