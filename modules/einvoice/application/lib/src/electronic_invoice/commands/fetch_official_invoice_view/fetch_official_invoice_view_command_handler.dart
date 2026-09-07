import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../exceptions/provider_call_ambiguous_exception.dart';
import '../../../ports/i_electronic_invoice_command_gateway.dart';
import '../../../ports/i_electronic_invoice_provider_port.dart';
import '../../../ports/i_provider_interaction_gateway.dart';
import '../../shared/electronic_invoice_provider_context_dto.dart';
import '../../shared/official_view_result_record.dart';
import '../../shared/provider_call_correlation_id.dart';
import 'fetch_official_invoice_view_command.dart';

@CommandHandlerFor(FetchOfficialInvoiceViewCommand)
final class FetchOfficialInvoiceViewCommandHandler
    implements ICommandHandler<FetchOfficialInvoiceViewCommand, void> {
  FetchOfficialInvoiceViewCommandHandler({
    required IElectronicInvoiceCommandGateway commandGateway,
    required IElectronicInvoiceProviderPort providerPort,
    required IProviderInteractionGateway interactionGateway,
  }) : _commandGateway = commandGateway,
       _providerPort = providerPort,
       _interactionGateway = interactionGateway;

  final IElectronicInvoiceCommandGateway _commandGateway;
  final IElectronicInvoiceProviderPort _providerPort;
  final IProviderInteractionGateway _interactionGateway;

  @override
  Future<void> handle(FetchOfficialInvoiceViewCommand command) async {
    final context = await _commandGateway.loadOfficialViewContext(
      tenantId: command.tenantId,
      operationId: command.operationId,
    );
    if (context == null || context.status != InvoiceDocumentStatus.pending) {
      return;
    }

    final correlationId = ProviderCallCorrelationId.forWorkerAttempt(
      commandId: command.id,
      workerAttemptNumber: command.workerAttemptNumber,
    );

    final interaction = await _interactionGateway.start(
      tenantId: command.tenantId,
      providerConnectionId: context.providerConnectionId,
      direction: ProviderInteractionDirection.outbound,
      operationType: FetchOfficialInvoiceViewCommand.type,
      targetType: 'OFFICIAL_VIEW_OPERATION',
      targetId: command.operationId,
      correlationId: correlationId,
      requestReference: command.id,
    );

    if (interaction.status == ProviderInteractionStatus.completed) {
      return;
    }

    try {
      final outcome = await _providerPort.fetchOfficialView(
        ElectronicInvoiceProviderContextDto(
          tenantId: context.tenantId,
          providerConnectionId: context.providerConnectionId,
          electronicInvoiceId: context.electronicInvoiceId,
          providerInvoiceReference: context.providerInvoiceReference,
          invoiceSeries: context.invoiceSeries,
          operationId: context.operationId,
        ),
      );

      await _finalizeAndRecord(
        command: command,
        context: context,
        interaction: interaction,
        outcome: outcome,
      );
    } on ProviderCallAmbiguousException catch (error) {
      await _interactionGateway.finalize(
        tenantId: command.tenantId,
        interactionReference: interaction.interactionReference,
        expectedVersion: interaction.version,
        outcome: ProviderInteractionOutcome.timeout,
        safeErrorCode: error.safeErrorCode,
      );
      throw StateError(error.safeErrorCode);
    }
  }

  Future<void> _finalizeAndRecord({
    required FetchOfficialInvoiceViewCommand command,
    required OfficialViewOperationContextDto context,
    required ProviderInteractionRecord interaction,
    required OfficialViewProviderOutcome outcome,
  }) async {
    switch (outcome) {
      case OfficialViewProviderSuccess success:
        final finalized = await _interactionGateway.finalize(
          tenantId: command.tenantId,
          interactionReference: interaction.interactionReference,
          expectedVersion: interaction.version,
          outcome: ProviderInteractionOutcome.succeeded,
          providerReference: success.providerReference,
        );
        await _commandGateway.recordOfficialViewResult(
          OfficialViewResultRecord(
            tenantId: command.tenantId,
            operationId: context.operationId,
            status: InvoiceDocumentStatus.available,
            viewerUrl: success.viewerUrl,
            expiresAt: success.expiresAt,
            providerInteractionReference: finalized.interactionReference,
            expectedVersion: context.expectedVersion,
          ),
        );
      case OfficialViewProviderCheckRequired check:
        final finalized = await _interactionGateway.finalize(
          tenantId: command.tenantId,
          interactionReference: interaction.interactionReference,
          expectedVersion: interaction.version,
          outcome: ProviderInteractionOutcome.checkRequired,
          safeErrorCode: check.safeErrorCode,
          providerReference: check.providerReference,
        );
        await _commandGateway.recordOfficialViewResult(
          OfficialViewResultRecord(
            tenantId: command.tenantId,
            operationId: context.operationId,
            status: InvoiceDocumentStatus.checkRequired,
            failureCode: check.safeErrorCode,
            providerInteractionReference: finalized.interactionReference,
            expectedVersion: context.expectedVersion,
          ),
        );
      case OfficialViewProviderDefiniteFailure failure:
        final finalized = await _interactionGateway.finalize(
          tenantId: command.tenantId,
          interactionReference: interaction.interactionReference,
          expectedVersion: interaction.version,
          outcome: ProviderInteractionOutcome.definiteFailure,
          safeErrorCode: failure.failureCode,
          providerReference: failure.providerReference,
        );
        await _commandGateway.recordOfficialViewResult(
          OfficialViewResultRecord(
            tenantId: command.tenantId,
            operationId: context.operationId,
            status: InvoiceDocumentStatus.failed,
            failureCode: failure.failureCode,
            failureMessage: failure.failureMessage,
            providerInteractionReference: finalized.interactionReference,
            expectedVersion: context.expectedVersion,
          ),
        );
      case OfficialViewProviderAmbiguous ambiguous:
        await _interactionGateway.finalize(
          tenantId: command.tenantId,
          interactionReference: interaction.interactionReference,
          expectedVersion: interaction.version,
          outcome: ProviderInteractionOutcome.unavailable,
          safeErrorCode: ambiguous.safeErrorCode,
        );
        throw StateError(ambiguous.safeErrorCode);
    }
  }
}
