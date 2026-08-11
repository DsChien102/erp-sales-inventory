import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/tenant_member_detail_dto.dart';

@RequiresPermission(IamPermissions.memberStatusUpdate)
@RequiresTenant()
final class ReactivateMembershipCommand extends CommandBase<TenantMemberDetailDto>
    implements ICommand<TenantMemberDetailDto>, ITenantScopedCommand {
  ReactivateMembershipCommand({
    String? id,
    required this.tenantId,
    required this.membershipId,
    required this.expectedVersion,
  }) : super(id);

  @override
  final String tenantId;
  final String membershipId;
  final int expectedVersion;
}
