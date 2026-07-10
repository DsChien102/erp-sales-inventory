import 'package:vet45_partner_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/organization_profile_input.dart';
import 'transform_partner_result.dart';

@RequiresPermission(PartnerPermissions.transform)
@RequiresTenant()
final class TransformPersonToOrganizationCommand
    extends CommandBase<TransformPartnerResult>
    implements ICommand<TransformPartnerResult>, ITenantScopedCommand {
  TransformPersonToOrganizationCommand({
    String? id,
    required this.tenantId,
    required this.actorId,
    required this.partnerId,
    required this.organizationProfile,
    required this.expectedVersion,
    this.confirmDuplicate = false,
  }) : super(id);

  @override
  final String tenantId;
  final String actorId;
  final String partnerId;
  final OrganizationProfileInput organizationProfile;
  final int expectedVersion;
  final bool confirmDuplicate;
}
