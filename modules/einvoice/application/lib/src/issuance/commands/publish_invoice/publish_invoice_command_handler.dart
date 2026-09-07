import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_issuance_result_gateway.dart';
import '../../../ports/i_me_invoice_provider_port.dart';
import '../../../ports/me_invoice_publish_outcome.dart';
import '../../shared/canonical_invoice_integrity_exception.dart';
import '../../shared/issuance_result_evidence_dto.dart';
import '../../shared/publish_preparation_action.dart';
import 'publish_invoice_command.dart';

@CommandHandlerFor(PublishInvoiceCommand)
final class PublishInvoiceCommandHandler implements ICommandHandler<PublishInvoiceCommand, void> {
  PublishInvoiceCommandHandler({
    required IMeInvoiceProviderPort providerPort,
    required IIssuanceResultGateway resultGateway,
  }) : _providerPort = providerPort,
       _resultGateway = resultGateway;

  final IMeInvoiceProviderPort _providerPort;
  final IIssuanceResultGateway _resultGateway;

  @override
  Future<void> handle(PublishInvoiceCommand command) async {
    try {
      _providerPort.validateCanonical(canonicalInvoice: command.canonicalInvoice);
    } catch (error) {
      if (error is CanonicalInvoiceIntegrityException) {
        rethrow;
      }
      throw CanonicalInvoiceIntegrityException(
        attemptId: command.attemptId,
        reasonCode: 'COMMAND_INTEGRITY',
        message: error.toString(),
      );
    }

    final preparation = await _resultGateway.preparePublish(
      tenantId: command.tenantId,
      attemptId: command.attemptId,
      idempotencyKey: command.idempotencyKey,
      payloadHash: command.payloadHash,
      canonicalInvoice: command.canonicalInvoice,
    );

    switch (preparation.action) {
      case PublishPreparationAction.skip:
        return;
      case PublishPreparationAction.reconcileOnly:
        await _resultGateway.recordUndetermined(
          tenantId: command.tenantId,
          attemptId: command.attemptId,
          evidence: IssuanceResultEvidenceDto.undetermined(
            idempotencyKey: command.idempotencyKey,
            payloadHash: command.payloadHash,
            reasonCode: 'DISPATCH_STATE_UNCERTAIN',
          ),
        );
        return;
      case PublishPreparationAction.callProvider:
        break;
    }

    await _resultGateway.markProviderCallStarted(
      tenantId: command.tenantId,
      attemptId: command.attemptId,
    );

    final outcome = await _providerPort.publish(
      tenantId: command.tenantId,
      canonicalInvoice: command.canonicalInvoice,
      idempotencyKey: command.idempotencyKey,
    );

    switch (outcome) {
      case MeInvoicePublishSuccess():
        await _resultGateway.recordSuccess(
          tenantId: command.tenantId,
          attemptId: command.attemptId,
          evidence: IssuanceResultEvidenceDto.success(
            idempotencyKey: command.idempotencyKey,
            payloadHash: command.payloadHash,
            providerReference: outcome.providerReference,
            invoiceNumber: outcome.invoiceNumber,
            invoiceSeries: outcome.invoiceSeries,
            issuedAt: outcome.issuedAt,
          ),
        );
      case MeInvoicePublishDefiniteFailure():
        await _resultGateway.recordDefiniteFailure(
          tenantId: command.tenantId,
          attemptId: command.attemptId,
          evidence: IssuanceResultEvidenceDto.definiteFailure(
            idempotencyKey: command.idempotencyKey,
            payloadHash: command.payloadHash,
            providerCode: outcome.providerCode,
            providerMessage: outcome.providerMessage,
          ),
        );
      case MeInvoicePublishUndetermined():
        await _resultGateway.recordUndetermined(
          tenantId: command.tenantId,
          attemptId: command.attemptId,
          evidence: IssuanceResultEvidenceDto.undetermined(
            idempotencyKey: command.idempotencyKey,
            payloadHash: command.payloadHash,
            reasonCode: outcome.reasonCode,
          ),
        );
    }
  }
}
