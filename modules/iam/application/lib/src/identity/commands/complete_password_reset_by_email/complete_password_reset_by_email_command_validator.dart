import 'package:vet45_iam_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'complete_password_reset_by_email_command.dart';

final class CompletePasswordResetByEmailCommandValidator
    implements ICommandValidator<CompletePasswordResetByEmailCommand> {
  @override
  Future<void> validate(CompletePasswordResetByEmailCommand command) async {
    if (command.operationId.trim().isEmpty) {
      throw ValidationException('operationId is required');
    }
    if (!PasswordPolicy.isValid(command.newPassword)) {
      throw ValidationException('PASSWORD_POLICY_VIOLATION');
    }
  }
}
