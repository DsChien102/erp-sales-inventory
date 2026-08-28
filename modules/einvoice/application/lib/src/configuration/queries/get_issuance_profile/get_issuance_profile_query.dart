import 'package:vet45_einvoice_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';
import 'issuance_profile_dto.dart';

@RequiresPermission(EInvoicePermissions.manageConfiguration)
@RequiresTenant()
final class GetIssuanceProfileQuery extends QueryBase<IssuanceProfileDto>
    implements IQuery<IssuanceProfileDto>, ITenantScopedCommand {
  GetIssuanceProfileQuery({
    String? id,
    required this.tenantId,
    required this.actorId,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
}
