import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/organization_profile_input.dart';
import '../../shared/person_profile_input.dart';
import 'create_partner_result.dart';

@RequiresPermission(PartnerPermissions.create)
@RequiresTenant()
final class CreatePartnerCommand extends CommandBase<CreatePartnerResult>
    implements ICommand<CreatePartnerResult>, ITenantScopedCommand {
  CreatePartnerCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.partnerType,
    required this.roles,
    this.personProfile,
    this.organizationProfile,
    this.confirmDuplicate = false,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final PartnerType partnerType;
  final List<PartnerRoleType> roles;
  final PersonProfileInput? personProfile;
  final OrganizationProfileInput? organizationProfile;
  final bool confirmDuplicate;
}
