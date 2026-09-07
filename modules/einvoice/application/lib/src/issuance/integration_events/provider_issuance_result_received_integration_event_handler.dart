import 'package:vet45_einvoice_integration_events/integration_events.dart';

import '../../ports/i_einvoice_command_dispatcher.dart';
import '../commands/record_issuance_result/record_issuance_result_command.dart';
import '../shared/issuance_result_evidence_dto.dart';

final class ProviderIssuanceResultReceivedIntegrationEventHandler
    implements
        IIntegrationEventNotificationHandler<ProviderIssuanceResultReceivedIntegrationEvent> {
  ProviderIssuanceResultReceivedIntegrationEventHandler({
    required IEinvoiceCommandDispatcher commands,
  }) : _commands = commands;

  final IEinvoiceCommandDispatcher _commands;

  @override
  Future<void> handle(
    ProviderIssuanceResultReceivedIntegrationEvent event,
  ) async {
    final IssuanceResultEvidenceDto evidence = switch (event.outcome) {
      ProviderIssuanceOutcome.success => IssuanceResultEvidenceDto.success(
        idempotencyKey: event.idempotencyKey,
        payloadHash: event.payloadHash,
        providerReference: event.providerReference ?? '',
        invoiceNumber: event.invoiceNumber!,
        invoiceSeries: event.invoiceSeries!,
        issuedAt: event.issuedAt!,
      ),
      ProviderIssuanceOutcome.definiteFailure => IssuanceResultEvidenceDto.definiteFailure(
        idempotencyKey: event.idempotencyKey,
        payloadHash: event.payloadHash,
        providerCode: event.errorCode!,
        providerMessage: event.errorMessage!,
      ),
      ProviderIssuanceOutcome.undetermined => IssuanceResultEvidenceDto.undetermined(
        idempotencyKey: event.idempotencyKey,
        payloadHash: event.payloadHash,
        reasonCode: event.reasonCode!,
      ),
    };

    await _commands.execute(
      RecordIssuanceResultCommand(
        tenantId: event.tenantId,
        attemptId: event.attemptId,
        correlationId: event.correlationId,
        evidence: evidence,
      ),
    );
  }
}
