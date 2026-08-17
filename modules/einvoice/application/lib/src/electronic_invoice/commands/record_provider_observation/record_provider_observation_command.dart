import 'package:vet45_shared_application/application.dart';

import 'record_provider_observation_result.dart';

@RequiresTenant()
final class RecordProviderObservationCommand extends CommandBase<ProviderObservationDto>
    implements ICommand<ProviderObservationDto>, ITenantScopedCommand {
  RecordProviderObservationCommand({
    String? id,
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.observationPayload,
    required this.source,
  }) : super(id);

  @override
  final String tenantId;
  final String electronicInvoiceId;
  final Map<String, Object?> observationPayload;
  final String source;
}
