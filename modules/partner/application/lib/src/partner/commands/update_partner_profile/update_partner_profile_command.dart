import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/organization_profile_input.dart';
import '../../shared/person_profile_input.dart';
import 'update_partner_profile_result.dart';

@RequiresPermission(PartnerPermissions.update)
@RequiresTenant()
final class UpdatePartnerProfileCommand
    extends CommandBase<UpdatePartnerProfileResult>
    implements ICommand<UpdatePartnerProfileResult>, ITenantScopedCommand {
  UpdatePartnerProfileCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.partnerId,
    required this.roles,
    required this.expectedVersion,
    this.personProfile,
    this.organizationProfile,
    this.confirmDuplicate = false,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String partnerId;
  final List<PartnerRoleType> roles;
  final int expectedVersion;
  final PersonProfileInput? personProfile;
  final OrganizationProfileInput? organizationProfile;
  final bool confirmDuplicate;
}
