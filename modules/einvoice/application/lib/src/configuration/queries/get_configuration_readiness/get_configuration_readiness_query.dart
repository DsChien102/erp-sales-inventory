import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'configuration_readiness_dto.dart';

@RequiresPermission(EInvoicePermissions.manageConfiguration)
@RequiresTenant()
final class GetConfigurationReadinessQuery extends QueryBase<ConfigurationReadinessDto>
    implements IQuery<ConfigurationReadinessDto>, ITenantScopedCommand {
  GetConfigurationReadinessQuery({
    String? id,
    required this.tenantId,
    required this.actorId,
    this.purpose,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final IssuancePurpose? purpose;
}
