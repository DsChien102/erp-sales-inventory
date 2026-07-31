import 'package:vet45_shared_application/application.dart';

import 'revoke_invitation_command.dart';

final class RevokeInvitationCommandValidator
    implements ICommandValidator<RevokeInvitationCommand> {
  @override
  Future<void> validate(RevokeInvitationCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.invitationId.trim().isEmpty) {
      throw ValidationException('invitationId is required');
    }
    if (command.expectedVersion < 1) {
      throw ValidationException('expectedVersion must be >= 1');
    }
    if (command.reason.trim().isEmpty) {
      throw ValidationException('reason is required');
    }
    if (command.idempotencyKey.trim().isEmpty) {
      throw ValidationException('idempotencyKey is required');
    }
  }
}
