import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

@RequiresPermission(PartnerPermissions.contactManage)
@RequiresTenant()
final class RemoveOrganizationContactCommand extends CommandBase<void>
    implements ICommand<void>, ITenantScopedCommand {
  RemoveOrganizationContactCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.organizationPartnerId,
    required this.personPartnerId,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String organizationPartnerId;
  final String personPartnerId;
}
