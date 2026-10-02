import 'package:vet45_einvoice_application/application.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../exceptions/provider_call_ambiguous_exception.dart';
import '../../../ports/i_einvoice_command_dispatcher.dart';
import '../../../ports/i_electronic_invoice_command_gateway.dart';
import '../../../ports/i_electronic_invoice_provider_port.dart';
import '../../shared/electronic_invoice_provider_context_dto.dart';
import '../record_provider_observation/record_provider_observation_command.dart';
import 'poll_provider_observation_command.dart';

@CommandHandlerFor(PollProviderObservationCommand)
final class PollProviderObservationCommandHandler
    implements ICommandHandler<PollProviderObservationCommand, void> {
  PollProviderObservationCommandHandler({
    required IElectronicInvoiceCommandGateway commandGateway,
    required IElectronicInvoiceProviderPort providerPort,
    required IEinvoiceCommandDispatcher commandDispatcher,
  }) : _commandGateway = commandGateway,
       _providerPort = providerPort,
       _commandDispatcher = commandDispatcher;

  final IElectronicInvoiceCommandGateway _commandGateway;
  final IElectronicInvoiceProviderPort _providerPort;
  final IEinvoiceCommandDispatcher _commandDispatcher;

  @override
  Future<void> handle(PollProviderObservationCommand command) async {
    final context = await _commandGateway.loadObservationContext(
      tenantId: command.tenantId,
      commandId: command.id,
    );
    if (context == null) {
      return;
    }

    final ProviderObservationOutcome outcome;
    try {
      outcome = await _providerPort.observe(
        ElectronicInvoiceProviderContextDto(
          tenantId: context.tenantId,
          providerConnectionId: context.providerConnectionId,
          electronicInvoiceId: context.electronicInvoiceId,
          providerInvoiceReference: context.providerInvoiceReference,
          invoiceSeries: context.invoiceSeries,
          operationId: context.commandId,
        ),
      );
    } on ProviderCallAmbiguousException catch (error) {
      // Do not invent an observation when MISA did not answer. Leave the
      // command to retry.
      throw StateError(error.safeErrorCode);
    }

    switch (outcome) {
      case ProviderObservationAmbiguous ambiguous:
        throw StateError(ambiguous.safeErrorCode);
      case ProviderObservationFound():
      case ProviderObservationNotFound():
      case ProviderObservationMismatch():
        final record = _observationFields(outcome);
        await _commandDispatcher.execute(
          RecordProviderObservationCommand(
            tenantId: command.tenantId,
            electronicInvoiceId: context.electronicInvoiceId,
            providerStateCode: record.providerStateCode,
            safeDescription: record.safeDescription,
            providerReference: record.providerReference,
            observedAt: record.observedAt,
            deduplicationKey: 'provider_observation:${command.id}',
            detailsSnapshot: record.detailsSnapshot,
            correlationId: context.correlationId,
            source: 'WORKER',
          ),
        );
    }
  }

  ({
    String providerStateCode,
    String safeDescription,
    String? providerReference,
    DateTime observedAt,
    Map<String, Object?> detailsSnapshot,
  })
  _observationFields(ProviderObservationOutcome outcome) {
    switch (outcome) {
      case ProviderObservationFound found:
        return (
          providerStateCode: found.providerStateCode,
          safeDescription: found.safeDescription,
          providerReference: found.providerReference,
          observedAt: found.observedAt,
          detailsSnapshot: found.detailsSnapshot,
        );
      case ProviderObservationNotFound notFound:
        return (
          providerStateCode: notFound.providerStateCode,
          safeDescription: notFound.safeDescription,
          providerReference: notFound.providerReference,
          detailsSnapshot: const <String, Object?>{},
          observedAt: notFound.observedAt,
        );
      case ProviderObservationMismatch mismatch:
        return (
          providerStateCode: mismatch.providerStateCode,
          safeDescription: mismatch.safeDescription,
          providerReference: mismatch.providerReference,
          detailsSnapshot: const <String, Object?>{},
          observedAt: mismatch.observedAt,
        );
      case ProviderObservationAmbiguous():
        throw StateError('ambiguous observation cannot be recorded');
    }
  }
}
