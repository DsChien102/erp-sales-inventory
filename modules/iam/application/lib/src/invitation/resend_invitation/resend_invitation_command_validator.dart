import 'package:vet45_shared_application/application.dart';

import 'resend_invitation_command.dart';

final class ResendInvitationCommandValidator
    implements ICommandValidator<ResendInvitationCommand> {
  @override
  Future<void> validate(ResendInvitationCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.invitationId.trim().isEmpty) {
      throw ValidationException('invitationId is required');
    }
    if (command.expectedVersion < 1) {
      throw ValidationException('expectedVersion must be >= 1');
    }
    if (command.idempotencyKey.trim().isEmpty) {
      throw ValidationException('idempotencyKey is required');
    }
  }
}
