import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../exceptions/provider_call_ambiguous_exception.dart';
import '../../../ports/i_electronic_invoice_command_gateway.dart';
import '../../../ports/i_electronic_invoice_provider_port.dart';
import '../../../ports/i_invoice_document_storage_port.dart';
import '../../../ports/i_provider_interaction_gateway.dart';
import '../../shared/electronic_invoice_provider_context_dto.dart';
import '../../shared/invoice_document_result_record.dart';
import '../../shared/provider_call_correlation_id.dart';
import 'download_invoice_document_command.dart';

@CommandHandlerFor(DownloadInvoiceDocumentCommand)
final class DownloadInvoiceDocumentCommandHandler
    implements ICommandHandler<DownloadInvoiceDocumentCommand, void> {
  DownloadInvoiceDocumentCommandHandler({
    required IElectronicInvoiceCommandGateway commandGateway,
    required IElectronicInvoiceProviderPort providerPort,
    required IProviderInteractionGateway interactionGateway,
    required IInvoiceDocumentStoragePort storagePort,
  }) : _commandGateway = commandGateway,
       _providerPort = providerPort,
       _interactionGateway = interactionGateway,
       _storagePort = storagePort;

  final IElectronicInvoiceCommandGateway _commandGateway;
  final IElectronicInvoiceProviderPort _providerPort;
  final IProviderInteractionGateway _interactionGateway;
  final IInvoiceDocumentStoragePort _storagePort;

  @override
  Future<void> handle(DownloadInvoiceDocumentCommand command) async {
    final context = await _commandGateway.loadDocumentContext(
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
      operationType: DownloadInvoiceDocumentCommand.type,
      targetType: 'INVOICE_DOCUMENT_OPERATION',
      targetId: command.operationId,
      correlationId: correlationId,
      requestReference: command.id,
    );

    if (interaction.status == ProviderInteractionStatus.completed) {
      return;
    }

    try {
      final outcome = await _providerPort.downloadDocument(
        ElectronicInvoiceProviderContextDto(
          tenantId: context.tenantId,
          providerConnectionId: context.providerConnectionId,
          electronicInvoiceId: context.electronicInvoiceId,
          providerInvoiceReference: context.providerInvoiceReference,
          invoiceSeries: context.invoiceSeries,
          operationId: context.operationId,
          documentType: context.documentType,
          documentVersion: context.documentVersion,
        ),
        context.documentType,
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
    required DownloadInvoiceDocumentCommand command,
    required InvoiceDocumentOperationContextDto context,
    required ProviderInteractionRecord interaction,
    required InvoiceDocumentProviderOutcome outcome,
  }) async {
    switch (outcome) {
      case InvoiceDocumentProviderSuccess success:
        final stored = await _storagePort.store(
          tenantId: command.tenantId,
          electronicInvoiceId: context.electronicInvoiceId,
          documentType: context.documentType,
          documentVersion: context.documentVersion,
          bytes: success.bytes,
        );
        final finalized = await _interactionGateway.finalize(
          tenantId: command.tenantId,
          interactionReference: interaction.interactionReference,
          expectedVersion: interaction.version,
          outcome: ProviderInteractionOutcome.succeeded,
          providerReference: success.providerReference,
        );
        await _commandGateway.recordDocumentResult(
          InvoiceDocumentResultRecord(
            tenantId: command.tenantId,
            operationId: context.operationId,
            status: InvoiceDocumentStatus.available,
            fileRef: stored.storageReference,
            checksum: stored.checksum,
            contentType: stored.contentType,
            fileName: stored.fileName,
            fileSize: stored.fileSize,
            providerInteractionReference: finalized.interactionReference,
            expectedOperationVersion: context.expectedVersion,
            expectedDocumentVersion: context.documentVersion,
            invoiceDocumentId: context.invoiceDocumentId,
          ),
        );
      case InvoiceDocumentProviderCheckRequired check:
        final finalized = await _interactionGateway.finalize(
          tenantId: command.tenantId,
          interactionReference: interaction.interactionReference,
          expectedVersion: interaction.version,
          outcome: ProviderInteractionOutcome.checkRequired,
          safeErrorCode: check.safeErrorCode,
          providerReference: check.providerReference,
        );
        await _commandGateway.recordDocumentResult(
          InvoiceDocumentResultRecord(
            tenantId: command.tenantId,
            operationId: context.operationId,
            status: InvoiceDocumentStatus.checkRequired,
            failureCode: check.safeErrorCode,
            providerInteractionReference: finalized.interactionReference,
            expectedOperationVersion: context.expectedVersion,
            expectedDocumentVersion: context.documentVersion,
            invoiceDocumentId: context.invoiceDocumentId,
          ),
        );
      case InvoiceDocumentProviderDefiniteFailure failure:
        final finalized = await _interactionGateway.finalize(
          tenantId: command.tenantId,
          interactionReference: interaction.interactionReference,
          expectedVersion: interaction.version,
          outcome: ProviderInteractionOutcome.definiteFailure,
          safeErrorCode: failure.failureCode,
          providerReference: failure.providerReference,
        );
        await _commandGateway.recordDocumentResult(
          InvoiceDocumentResultRecord(
            tenantId: command.tenantId,
            operationId: context.operationId,
            status: InvoiceDocumentStatus.failed,
            failureCode: failure.failureCode,
            failureMessage: failure.failureMessage,
            providerInteractionReference: finalized.interactionReference,
            expectedOperationVersion: context.expectedVersion,
            expectedDocumentVersion: context.documentVersion,
            invoiceDocumentId: context.invoiceDocumentId,
          ),
        );
      case InvoiceDocumentProviderAmbiguous ambiguous:
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
