import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/provider_observation_dto.dart';

@RequiresPermission(EInvoicePermissions.view)
@RequiresTenant()
final class GetLatestProviderObservationQuery extends QueryBase<ProviderObservationDto?>
    implements IQuery<ProviderObservationDto?>, ITenantScopedCommand {
  GetLatestProviderObservationQuery({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.salesOrderId,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String salesOrderId;
}
