import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/invitation_detail_dto.dart';

/// Create a pending tenant invitation (EP-03/US-02 / §S7).
///
/// Actor is resolved from execution context — never from command input.
@RequiresPermission(IamPermissions.memberInvite)
@RequiresTenant()
@Idempotent(keyField: 'idempotencyKey')
final class CreateInvitationCommand extends CommandBase<InvitationDetailDto>
    implements ICommand<InvitationDetailDto>, ITenantScopedCommand {
  CreateInvitationCommand({
    String? id,
    required this.tenantId,
    required this.inviteeEmail,
    required this.initialRoleId,
    required this.idempotencyKey,
  }) : super(id);

  @override
  final String tenantId;
  final String inviteeEmail;
  final String initialRoleId;
  final String idempotencyKey;
}
