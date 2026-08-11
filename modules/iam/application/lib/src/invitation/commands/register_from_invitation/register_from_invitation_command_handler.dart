import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_invitation_identity_port.dart';
import '../../../ports/i_tenant_invitation_acceptance_port.dart';
import '../../../shared/iam_blocked_codes.dart';
import '../../../shared/iam_blocked_exception.dart';
import '../../shared/invitation_registration_result_dto.dart';
import 'register_from_invitation_command.dart';

@CommandHandlerFor(RegisterFromInvitationCommand)
final class RegisterFromInvitationCommandHandler
    implements
        ICommandHandler<
          RegisterFromInvitationCommand,
          InvitationRegistrationResultDto
        > {
  RegisterFromInvitationCommandHandler({
    required ITenantInvitationAcceptancePort acceptancePort,
    required IInvitationIdentityPort identityPort,
  }) : _acceptancePort = acceptancePort,
       _identityPort = identityPort;

  final ITenantInvitationAcceptancePort _acceptancePort;
  final IInvitationIdentityPort _identityPort;

  @override
  Future<InvitationRegistrationResultDto> handle(
    RegisterFromInvitationCommand command,
  ) async {
    final token = command.token.trim();
    final key = command.idempotencyKey.trim();
    if (token.isEmpty) {
      throw const IamBlockedException(IamBlockedCodes.invitationTokenInvalid);
    }
    if (key.isEmpty) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }
    if (!PasswordPolicy.isValid(command.credentialProof.trim())) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }
    if (command.profile.givenName.trim().isEmpty ||
        command.profile.familyName.trim().isEmpty) {
      throw const IamBlockedException(IamBlockedCodes.validationError);
    }

    // Inspect first (does not consume). Invalid tokens must not leak accountExists.
    final inspection = await _acceptancePort.inspectToken(token);
    if (inspection.accountExists) {
      throw const IamBlockedException(IamBlockedCodes.platformUserAlreadyExists);
    }

    final userId = await _identityPort.registerVerifiedFromInvitation(
      inviteeEmail: inspection.inviteeEmail,
      profile: command.profile,
      credentialProof: command.credentialProof.trim(),
    );

    final membership = await _acceptancePort.acceptInvitation(
      token: token,
      idempotencyKey: key,
    );

    return InvitationRegistrationResultDto(
      userId: userId,
      membership: membership,
    );
  }
}
