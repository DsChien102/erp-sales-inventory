import 'package:vet45_shared_application/application.dart';

import '../../shared/provider_observation_dto.dart';

@RequiresTenant()
final class RecordProviderObservationCommand extends CommandBase<ProviderObservationDto>
    implements ICommand<ProviderObservationDto>, ITenantScopedCommand {
  RecordProviderObservationCommand({
    String? id,
    required this.tenantId,
    required this.electronicInvoiceId,
    required this.providerStateCode,
    this.safeDescription,
    this.providerReference,
    required this.observedAt,
    required this.deduplicationKey,
    required this.detailsSnapshot,
    required this.providerInteractionReference,
    required this.source,
  }) : super(id);

  @override
  final String tenantId;
  final String electronicInvoiceId;
  final String providerStateCode;
  final String? safeDescription;
  final String? providerReference;
  final DateTime observedAt;
  final String deduplicationKey;
  final Map<String, Object?> detailsSnapshot;
  final String providerInteractionReference;
  final String source;
}
