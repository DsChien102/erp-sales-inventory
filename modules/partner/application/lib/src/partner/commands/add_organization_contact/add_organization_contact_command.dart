import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/person_profile_input.dart';
import 'add_organization_contact_result.dart';

@RequiresPermission(PartnerPermissions.contactManage)
@RequiresTenant()
final class AddOrganizationContactCommand
    extends CommandBase<AddOrganizationContactResult>
    implements ICommand<AddOrganizationContactResult>, ITenantScopedCommand {
  AddOrganizationContactCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.organizationPartnerId,
    this.personPartnerId,
    this.newPersonProfile,
    this.contactRole,
    this.isPrimary = false,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String organizationPartnerId;
  final String? personPartnerId;
  final PersonProfileInput? newPersonProfile;
  final String? contactRole;
  final bool isPrimary;
}
