import 'package:vet45_shared_application/application.dart';

import '../shared/invitation_detail_dto.dart';

/// Decline invitation via opaque token (§S8).
@PublicAccess()
@Idempotent(keyField: 'idempotencyKey')
final class DeclineInvitationCommand extends CommandBase<InvitationDetailDto>
    implements ICommand<InvitationDetailDto> {
  DeclineInvitationCommand({
    String? id,
    required this.token,
    required this.idempotencyKey,
  }) : super(id);

  final String token;
  final String idempotencyKey;
}
