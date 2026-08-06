import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'complete_my_password_reset_command.dart';

final class CompleteMyPasswordResetCommandValidator
    implements ICommandValidator<CompleteMyPasswordResetCommand> {
  @override
  Future<void> validate(CompleteMyPasswordResetCommand command) async {
    if (command.operationId.trim().isEmpty) {
      throw ValidationException('operationId is required');
    }
    if (!PasswordPolicy.isValid(command.newPassword)) {
      throw ValidationException('PASSWORD_POLICY_VIOLATION');
    }
  }
}
