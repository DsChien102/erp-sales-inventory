import 'package:vet45_shared_application/application.dart';

import 'resend_my_password_reset_command.dart';

final class ResendMyPasswordResetCommandValidator
    implements ICommandValidator<ResendMyPasswordResetCommand> {
  @override
  Future<void> validate(ResendMyPasswordResetCommand command) async {
    if (command.operationId.trim().isEmpty) {
      throw ValidationException('operationId is required');
    }
  }
}
