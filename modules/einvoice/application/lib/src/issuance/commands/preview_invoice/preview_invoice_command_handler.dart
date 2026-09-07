import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_invoice_preview_gateway.dart';
import '../../../ports/i_me_invoice_provider_port.dart';
import '../../../ports/i_provider_interaction_gateway.dart';
import 'preview_invoice_command.dart';

@CommandHandlerFor(PreviewInvoiceCommand)
final class PreviewInvoiceCommandHandler implements ICommandHandler<PreviewInvoiceCommand, void> {
  PreviewInvoiceCommandHandler({
    required IMeInvoiceProviderPort providerPort,
    required IInvoicePreviewGateway previewGateway,
    required IProviderInteractionGateway interactionGateway,
  }) : _providerPort = providerPort,
       _previewGateway = previewGateway,
       _interactionGateway = interactionGateway;

  final IMeInvoiceProviderPort _providerPort;
  final IInvoicePreviewGateway _previewGateway;
  final IProviderInteractionGateway _interactionGateway;

  @override
  Future<void> handle(PreviewInvoiceCommand command) async {
    final correlationId = ProviderCallCorrelationId.forWorkerAttempt(
      commandId: command.id,
      workerAttemptNumber: command.workerAttemptNumber,
    );

    final interaction = await _interactionGateway.start(
      tenantId: command.tenantId,
      providerConnectionId: command.providerConnectionId,
      direction: ProviderInteractionDirection.outbound,
      operationType: PreviewInvoiceCommand.type,
      targetType: 'INVOICE_PREVIEW_OPERATION',
      targetId: command.previewRequestId,
      correlationId: correlationId,
      requestReference: command.id,
    );

    if (interaction.status == ProviderInteractionStatus.completed) {
      return;
    }

    try {
      final canonical = Map<String, Object?>.from(command.canonicalInvoice);
      // MISA unpublishview requires RefID; reuse preview operation id.
      canonical.putIfAbsent('refId', () => command.previewRequestId);

      final outcome = await _providerPort.previewUnpublished(
        tenantId: command.tenantId,
        canonicalInvoice: canonical,
      );

      if (!outcome.isSuccess) {
        await _interactionGateway.finalize(
          tenantId: command.tenantId,
          interactionReference: interaction.interactionReference,
          expectedVersion: interaction.version,
          outcome: outcome.authFailed
              ? ProviderInteractionOutcome.checkRequired
              : ProviderInteractionOutcome.unavailable,
          safeErrorCode: outcome.authFailed ? 'PROVIDER_AUTH_FAILED' : 'PROVIDER_UNAVAILABLE',
        );
        throw StateError(
          outcome.authFailed ? 'PROVIDER_NOT_CONNECTED' : 'PROVIDER_UNAVAILABLE',
        );
      }

      await _interactionGateway.finalize(
        tenantId: command.tenantId,
        interactionReference: interaction.interactionReference,
        expectedVersion: interaction.version,
        outcome: ProviderInteractionOutcome.succeeded,
      );

      await _previewGateway.storeResult(
        tenantId: command.tenantId,
        previewRequestId: command.previewRequestId,
        viewerRef: outcome.viewerRef,
      );
    } catch (error) {
      if (error is StateError &&
          (error.message == 'PROVIDER_NOT_CONNECTED' || error.message == 'PROVIDER_UNAVAILABLE')) {
        rethrow;
      }
      await _interactionGateway.finalize(
        tenantId: command.tenantId,
        interactionReference: interaction.interactionReference,
        expectedVersion: interaction.version,
        outcome: ProviderInteractionOutcome.timeout,
        safeErrorCode: 'PROVIDER_TIMEOUT',
      );
      rethrow;
    }
  }
}
