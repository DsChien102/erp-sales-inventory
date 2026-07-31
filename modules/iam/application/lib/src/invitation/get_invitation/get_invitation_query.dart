import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../shared/invitation_detail_dto.dart';

@RequiresPermission(IamPermissions.memberView)
@RequiresTenant()
final class GetInvitationQuery extends QueryBase<InvitationDetailDto>
    implements IQuery<InvitationDetailDto>, ITenantScopedCommand {
  GetInvitationQuery({
    String? id,
    required this.tenantId,
    required this.invitationId,
  }) : super(id);

  @override
  final String tenantId;
  final String invitationId;
}
