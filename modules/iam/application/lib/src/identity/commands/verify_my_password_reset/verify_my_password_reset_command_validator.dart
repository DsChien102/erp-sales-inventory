import 'package:vet45_shared_application/application.dart';

import 'verify_my_password_reset_command.dart';

final class VerifyMyPasswordResetCommandValidator
    implements ICommandValidator<VerifyMyPasswordResetCommand> {
  @override
  Future<void> validate(VerifyMyPasswordResetCommand command) async {
    if (command.operationId.trim().isEmpty) {
      throw ValidationException('operationId is required');
    }
    if (command.code.trim().isEmpty) {
      throw ValidationException('code is required');
    }
  }
}
