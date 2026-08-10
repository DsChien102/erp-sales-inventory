import 'package:vet45_shared_application/application.dart';

import '../../shared/invitation_registration_profile_input.dart';
import '../../shared/invitation_registration_result_dto.dart';

/// Register a new verified identity from invitation token, then accept (§S8).
@PublicAccess()
@Idempotent(keyField: 'idempotencyKey')
final class RegisterFromInvitationCommand
    extends CommandBase<InvitationRegistrationResultDto>
    implements ICommand<InvitationRegistrationResultDto> {
  RegisterFromInvitationCommand({
    String? id,
    required this.token,
    required this.profile,
    required this.credentialProof,
    required this.idempotencyKey,
  }) : super(id);

  final String token;
  final InvitationRegistrationProfileInput profile;
  final String credentialProof;
  final String idempotencyKey;
}
