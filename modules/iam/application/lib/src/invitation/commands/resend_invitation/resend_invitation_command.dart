import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../shared/invitation_detail_dto.dart';

/// Resend a pending tenant invitation (EP-03/US-04 / §S9).
@RequiresPermission(IamPermissions.memberInvite)
@RequiresTenant()
@Idempotent(keyField: 'idempotencyKey')
final class ResendInvitationCommand extends CommandBase<InvitationDetailDto>
    implements ICommand<InvitationDetailDto>, ITenantScopedCommand {
  ResendInvitationCommand({
    String? id,
    required this.tenantId,
    required this.invitationId,
    required this.expectedVersion,
    required this.idempotencyKey,
  }) : super(id);

  @override
  final String tenantId;
  final String invitationId;
  final int expectedVersion;
  final String idempotencyKey;
}
