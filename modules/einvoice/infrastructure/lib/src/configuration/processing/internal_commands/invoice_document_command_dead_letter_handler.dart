import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import 'i_einvoice_internal_command_client.dart';
import 'i_einvoice_internal_command_dead_letter_handler.dart';

final class InvoiceDocumentCommandDeadLetterHandler
    implements IEinvoiceInternalCommandDeadLetterHandler {
  InvoiceDocumentCommandDeadLetterHandler({
    required IElectronicInvoiceCommandGateway commandGateway,
  }) : _commandGateway = commandGateway;

  final IElectronicInvoiceCommandGateway _commandGateway;

  @override
  Future<void> handleDeadLetter({
    required String tenantId,
    required ClaimedInternalCommand command,
    required Object error,
  }) async {
    final electronicInvoiceId = command.payload['electronic_invoice_id']
        ?.toString();
    final requestId = command.payload['request_id']?.toString();
    final documentType = _documentType(
      command.payload['document_type']?.toString(),
    );
    if (electronicInvoiceId == null ||
        electronicInvoiceId.isEmpty ||
        requestId == null ||
        requestId.isEmpty ||
        documentType == null) {
      return;
    }

    final context = await _commandGateway.loadDocumentContext(
      tenantId: tenantId,
      electronicInvoiceId: electronicInvoiceId,
      documentType: documentType,
      requestId: requestId,
    );
    if (context == null || context.status != InvoiceDocumentStatus.pending) {
      return;
    }

    await _commandGateway.recordDocumentResult(
      InvoiceDocumentResultRecord(
        tenantId: tenantId,
        electronicInvoiceId: context.electronicInvoiceId,
        documentType: context.documentType,
        requestId: context.requestId,
        status: InvoiceDocumentStatus.checkRequired,
        failureCode: 'PROVIDER_RESULT_UNDETERMINED',
        failureMessage: error.toString(),
        failureSource: FailureSource.internal,
      ),
    );
  }

  InvoiceDocumentType? _documentType(String? raw) {
    return switch (raw?.toUpperCase()) {
      'PDF' => InvoiceDocumentType.pdf,
      'XML' => InvoiceDocumentType.xml,
      _ => null,
    };
  }
}
