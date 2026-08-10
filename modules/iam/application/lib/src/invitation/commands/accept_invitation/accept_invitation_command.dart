import 'package:vet45_shared_application/application.dart';

import '../../../tenant/shared/tenant_member_detail_dto.dart';

/// Accept invitation for authenticated actor (§S8).
///
/// Actor email is resolved from Auth session — never from command input.
@PublicAccess()
@Idempotent(keyField: 'idempotencyKey')
final class AcceptInvitationCommand extends CommandBase<TenantMemberDetailDto>
    implements ICommand<TenantMemberDetailDto> {
  AcceptInvitationCommand({
    String? id,
    required this.token,
    required this.idempotencyKey,
  }) : super(id);

  final String token;
  final String idempotencyKey;
}
