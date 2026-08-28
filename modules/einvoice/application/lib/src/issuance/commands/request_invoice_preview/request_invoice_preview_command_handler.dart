import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_invoice_preview_gateway.dart';
import '../../../ports/i_issuance_readiness_read_gateway.dart';
import '../../../shared/einvoice_blocked_codes.dart';
import '../../../shared/einvoice_blocked_exception.dart';
import 'request_invoice_preview_command.dart';
import 'request_invoice_preview_result.dart';

@CommandHandlerFor(RequestInvoicePreviewCommand)
final class RequestInvoicePreviewCommandHandler
    implements ICommandHandler<RequestInvoicePreviewCommand, InvoicePreviewResultDto> {
  RequestInvoicePreviewCommandHandler({
    required IIssuanceReadinessReadGateway readinessGateway,
    required IInvoicePreviewGateway previewGateway,
  }) : _readinessGateway = readinessGateway,
       _previewGateway = previewGateway;

  final IIssuanceReadinessReadGateway _readinessGateway;
  final IInvoicePreviewGateway _previewGateway;

  @override
  Future<InvoicePreviewResultDto> handle(
    RequestInvoicePreviewCommand command,
  ) async {
    final input = await _readinessGateway.load(
      tenantId: command.tenantId,
      actorId: command.actorId,
      salesOrderId: command.salesOrderId,
    );
    final evaluation = IssuanceReadinessEvaluator.evaluate(input);

    if (!evaluation.canPreview) {
      throw const EInvoiceBlockedException(
        EInvoiceBlockedCodes.issuanceNotReady,
        message: 'Không đủ điều kiện xem trước',
      );
    }

    await _previewGateway.persistRequestAndEnqueue(
      tenantId: command.tenantId,
      actorId: command.actorId,
      salesOrderId: command.salesOrderId,
      expectedOrderVersion: command.expectedOrderVersion,
    );

    return InvoicePreviewResultDto(
      viewerRef: null,
      previewPayload: null,
      warnings: [for (final w in evaluation.warnings) w.message],
    );
  }
}
