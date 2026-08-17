import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'provider_connection_screen_dto.dart';

@RequiresPermission(EInvoicePermissions.manageConfiguration)
@RequiresTenant()
final class GetProviderConnectionScreenQuery extends QueryBase<ProviderConnectionScreenDto>
    implements IQuery<ProviderConnectionScreenDto>, ITenantScopedCommand {
  GetProviderConnectionScreenQuery({
    String? id,
    required this.tenantId,
    required this.actorId,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;

}
