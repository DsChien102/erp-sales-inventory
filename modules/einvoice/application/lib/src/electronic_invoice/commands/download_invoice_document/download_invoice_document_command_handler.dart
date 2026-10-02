import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../exceptions/provider_call_ambiguous_exception.dart';
import '../../../ports/i_electronic_invoice_command_gateway.dart';
import '../../../ports/i_electronic_invoice_provider_port.dart';
import '../../../ports/i_invoice_document_storage_port.dart';
import '../../shared/electronic_invoice_provider_context_dto.dart';
import '../../shared/invoice_document_result_record.dart';
import 'download_invoice_document_command.dart';

@CommandHandlerFor(DownloadInvoiceDocumentCommand)
final class DownloadInvoiceDocumentCommandHandler
    implements ICommandHandler<DownloadInvoiceDocumentCommand, void> {
  DownloadInvoiceDocumentCommandHandler({
    required IElectronicInvoiceCommandGateway commandGateway,
    required IElectronicInvoiceProviderPort providerPort,
    required IInvoiceDocumentStoragePort storagePort,
  }) : _commandGateway = commandGateway,
       _providerPort = providerPort,
       _storagePort = storagePort;

  final IElectronicInvoiceCommandGateway _commandGateway;
  final IElectronicInvoiceProviderPort _providerPort;
  final IInvoiceDocumentStoragePort _storagePort;

  @override
  Future<void> handle(DownloadInvoiceDocumentCommand command) async {
    final context = await _commandGateway.loadDocumentContext(
      tenantId: command.tenantId,
      electronicInvoiceId: command.electronicInvoiceId,
      documentType: command.documentType,
      requestId: command.requestId,
    );
    if (context == null || context.status != InvoiceDocumentStatus.pending) {
      return;
    }

    final InvoiceDocumentProviderOutcome outcome;
    try {
      outcome = await _providerPort.downloadDocument(
        ElectronicInvoiceProviderContextDto(
          tenantId: context.tenantId,
          providerConnectionId: context.providerConnectionId,
          electronicInvoiceId: context.electronicInvoiceId,
          providerInvoiceReference: context.providerInvoiceReference,
          invoiceSeries: context.invoiceSeries,
          operationId: context.requestId,
          documentType: context.documentType,
        ),
        context.documentType,
      );
    } on ProviderCallAmbiguousException catch (error) {
      // Leave the row PENDING so the queue retries; the dead-letter handler
      // records CHECK_REQUIRED once retries are exhausted.
      throw StateError(error.safeErrorCode);
    }

    switch (outcome) {
      case InvoiceDocumentProviderSuccess success:
        final stored = await _storagePort.store(
          tenantId: command.tenantId,
          electronicInvoiceId: context.electronicInvoiceId,
          documentType: context.documentType,
          documentVersion: 1,
          bytes: success.bytes,
        );
        await _commandGateway.recordDocumentResult(
          InvoiceDocumentResultRecord(
            tenantId: command.tenantId,
            electronicInvoiceId: context.electronicInvoiceId,
            documentType: context.documentType,
            requestId: context.requestId,
            status: InvoiceDocumentStatus.available,
            fileRef: stored.storageReference,
            checksum: stored.checksum,
          ),
        );
      case InvoiceDocumentProviderCheckRequired check:
        await _commandGateway.recordDocumentResult(
          InvoiceDocumentResultRecord(
            tenantId: command.tenantId,
            electronicInvoiceId: context.electronicInvoiceId,
            documentType: context.documentType,
            requestId: context.requestId,
            status: InvoiceDocumentStatus.checkRequired,
            failureCode: check.safeErrorCode,
            failureSource: FailureSource.provider,
          ),
        );
      case InvoiceDocumentProviderDefiniteFailure failure:
        await _commandGateway.recordDocumentResult(
          InvoiceDocumentResultRecord(
            tenantId: command.tenantId,
            electronicInvoiceId: context.electronicInvoiceId,
            documentType: context.documentType,
            requestId: context.requestId,
            status: InvoiceDocumentStatus.failed,
            failureCode: failure.failureCode,
            failureMessage: failure.failureMessage,
            failureSource: FailureSource.provider,
          ),
        );
      case InvoiceDocumentProviderAmbiguous ambiguous:
        throw StateError(ambiguous.safeErrorCode);
    }
  }
}
