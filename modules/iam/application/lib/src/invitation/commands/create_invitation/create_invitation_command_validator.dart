import 'package:vet45_shared_application/application.dart';

import 'create_invitation_command.dart';

final class CreateInvitationCommandValidator
    implements ICommandValidator<CreateInvitationCommand> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Future<void> validate(CreateInvitationCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.idempotencyKey.trim().isEmpty) {
      throw ValidationException('idempotencyKey is required');
    }
    if (command.initialRoleId.trim().isEmpty) {
      throw ValidationException('initialRoleId is required');
    }

    final email = command.inviteeEmail.trim();
    if (email.isEmpty || !_emailPattern.hasMatch(email)) {
      throw ValidationException('Valid inviteeEmail is required');
    }
  }
}
