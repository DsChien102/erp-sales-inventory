import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_invoice_preview_gateway.dart';
import '../../../ports/i_me_invoice_provider_port.dart';
import 'preview_invoice_command.dart';

@CommandHandlerFor(PreviewInvoiceCommand)
final class PreviewInvoiceCommandHandler implements ICommandHandler<PreviewInvoiceCommand, void> {
  PreviewInvoiceCommandHandler({
    required IMeInvoiceProviderPort providerPort,
    required IInvoicePreviewGateway previewGateway,
  }) : _providerPort = providerPort,
       _previewGateway = previewGateway;

  final IMeInvoiceProviderPort _providerPort;
  final IInvoicePreviewGateway _previewGateway;

  @override
  Future<void> handle(PreviewInvoiceCommand command) async {
    final outcome = await _providerPort.previewUnpublished(
      tenantId: command.tenantId,
      canonicalInvoice: command.canonicalInvoice,
    );

    if (!outcome.isSuccess) {
      throw StateError(outcome.authFailed ? 'PROVIDER_NOT_CONNECTED' : 'PROVIDER_UNAVAILABLE');
    }

    await _previewGateway.storeResult(
      tenantId: command.tenantId,
      previewRequestId: command.previewRequestId,
      viewerRef: outcome.viewerRef,
    );
  }
}
