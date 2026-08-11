import 'package:vet45_shared_application/application.dart';

import 'resend_password_reset_by_email_command.dart';

final class ResendPasswordResetByEmailCommandValidator
    implements ICommandValidator<ResendPasswordResetByEmailCommand> {
  @override
  Future<void> validate(ResendPasswordResetByEmailCommand command) async {
    if (command.operationId.trim().isEmpty) {
      throw ValidationException('operationId is required');
    }
  }
}
