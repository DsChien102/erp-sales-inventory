import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';

import 'i_einvoice_internal_command_client.dart';
import 'i_einvoice_internal_command_dead_letter_handler.dart';

final class OfficialViewCommandDeadLetterHandler
    implements IEinvoiceInternalCommandDeadLetterHandler {
  OfficialViewCommandDeadLetterHandler({
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
    if (electronicInvoiceId == null ||
        electronicInvoiceId.isEmpty ||
        requestId == null ||
        requestId.isEmpty) {
      return;
    }

    final context = await _commandGateway.loadOfficialViewContext(
      tenantId: tenantId,
      electronicInvoiceId: electronicInvoiceId,
      requestId: requestId,
    );
    if (context == null || context.status != InvoiceDocumentStatus.pending) {
      return;
    }

    await _commandGateway.recordOfficialViewResult(
      OfficialViewResultRecord(
        tenantId: tenantId,
        electronicInvoiceId: context.electronicInvoiceId,
        requestId: context.requestId,
        status: InvoiceDocumentStatus.checkRequired,
        failureCode: 'PROVIDER_RESULT_UNDETERMINED',
        failureMessage: error.toString(),
        failureSource: FailureSource.internal,
      ),
    );
  }
}
