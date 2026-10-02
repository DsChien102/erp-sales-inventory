import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../exceptions/provider_call_ambiguous_exception.dart';
import '../../../ports/i_electronic_invoice_command_gateway.dart';
import '../../../ports/i_electronic_invoice_provider_port.dart';
import '../../shared/electronic_invoice_provider_context_dto.dart';
import '../../shared/official_view_result_record.dart';
import 'fetch_official_invoice_view_command.dart';

@CommandHandlerFor(FetchOfficialInvoiceViewCommand)
final class FetchOfficialInvoiceViewCommandHandler
    implements ICommandHandler<FetchOfficialInvoiceViewCommand, void> {
  FetchOfficialInvoiceViewCommandHandler({
    required IElectronicInvoiceCommandGateway commandGateway,
    required IElectronicInvoiceProviderPort providerPort,
  }) : _commandGateway = commandGateway,
       _providerPort = providerPort;

  final IElectronicInvoiceCommandGateway _commandGateway;
  final IElectronicInvoiceProviderPort _providerPort;

  @override
  Future<void> handle(FetchOfficialInvoiceViewCommand command) async {
    final context = await _commandGateway.loadOfficialViewContext(
      tenantId: command.tenantId,
      electronicInvoiceId: command.electronicInvoiceId,
      requestId: command.requestId,
    );
    if (context == null || context.status != InvoiceDocumentStatus.pending) {
      return;
    }

    final OfficialViewProviderOutcome outcome;
    try {
      outcome = await _providerPort.fetchOfficialView(
        ElectronicInvoiceProviderContextDto(
          tenantId: context.tenantId,
          providerConnectionId: context.providerConnectionId,
          electronicInvoiceId: context.electronicInvoiceId,
          providerInvoiceReference: context.providerInvoiceReference,
          invoiceSeries: context.invoiceSeries,
          operationId: context.requestId,
        ),
      );
    } on ProviderCallAmbiguousException catch (error) {
      // Leave the row PENDING so the queue retries; the dead-letter handler
      // records CHECK_REQUIRED once retries are exhausted.
      throw StateError(error.safeErrorCode);
    }

    final record = switch (outcome) {
      OfficialViewProviderSuccess success => OfficialViewResultRecord(
        tenantId: command.tenantId,
        electronicInvoiceId: context.electronicInvoiceId,
        requestId: context.requestId,
        status: InvoiceDocumentStatus.available,
        viewerUrl: success.viewerUrl,
        expiresAt: success.expiresAt,
      ),
      OfficialViewProviderCheckRequired check => OfficialViewResultRecord(
        tenantId: command.tenantId,
        electronicInvoiceId: context.electronicInvoiceId,
        requestId: context.requestId,
        status: InvoiceDocumentStatus.checkRequired,
        failureCode: check.safeErrorCode,
        failureSource: FailureSource.provider,
      ),
      OfficialViewProviderDefiniteFailure failure => OfficialViewResultRecord(
        tenantId: command.tenantId,
        electronicInvoiceId: context.electronicInvoiceId,
        requestId: context.requestId,
        status: InvoiceDocumentStatus.failed,
        failureCode: failure.failureCode,
        failureMessage: failure.failureMessage,
        failureSource: FailureSource.provider,
      ),
      OfficialViewProviderAmbiguous ambiguous =>
        throw StateError(ambiguous.safeErrorCode),
    };

    await _commandGateway.recordOfficialViewResult(record);
  }
}
