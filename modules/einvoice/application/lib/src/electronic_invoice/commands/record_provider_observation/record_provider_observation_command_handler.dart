import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_electronic_invoice_command_gateway.dart';
import '../../shared/provider_observation_dto.dart';
import '../../shared/provider_observation_record.dart';
import 'record_provider_observation_command.dart';

@CommandHandlerFor(RecordProviderObservationCommand)
final class RecordProviderObservationCommandHandler
    implements ICommandHandler<RecordProviderObservationCommand, ProviderObservationDto> {
  RecordProviderObservationCommandHandler({
    required IElectronicInvoiceCommandGateway gateway,
  }) : _gateway = gateway;

  final IElectronicInvoiceCommandGateway _gateway;

  @override
  Future<ProviderObservationDto> handle(
    RecordProviderObservationCommand command,
  ) {
    return _gateway.recordProviderObservation(
      ProviderObservationRecord(
        tenantId: command.tenantId,
        electronicInvoiceId: command.electronicInvoiceId,
        providerStateCode: command.providerStateCode,
        safeDescription: command.safeDescription,
        providerReference: command.providerReference,
        observedAt: command.observedAt,
        deduplicationKey: command.deduplicationKey,
        detailsSnapshot: command.detailsSnapshot,
        providerInteractionReference: command.providerInteractionReference,
        source: command.source,
      ),
    );
  }
}
