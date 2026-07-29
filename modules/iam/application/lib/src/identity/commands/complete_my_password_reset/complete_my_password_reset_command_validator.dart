import 'package:vet45_shared_application/application.dart';

import 'complete_my_password_reset_command.dart';

final class CompleteMyPasswordResetCommandValidator
    implements ICommandValidator<CompleteMyPasswordResetCommand> {
  @override
  Future<void> validate(CompleteMyPasswordResetCommand command) async {
    if (command.operationId.trim().isEmpty) {
      throw ValidationException('operationId is required');
    }
    if (command.newPassword.length < 8) {
      throw ValidationException('PASSWORD_POLICY_VIOLATION');
    }
  }
}
