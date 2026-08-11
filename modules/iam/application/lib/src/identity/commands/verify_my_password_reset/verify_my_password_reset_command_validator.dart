import 'package:vet45_shared_application/application.dart';

import 'verify_my_password_reset_command.dart';

final class VerifyMyPasswordResetCommandValidator
    implements ICommandValidator<VerifyMyPasswordResetCommand> {
  static final RegExp _sixDigitCode = RegExp(r'^\d{6}$');

  @override
  Future<void> validate(VerifyMyPasswordResetCommand command) async {
    if (command.operationId.trim().isEmpty) {
      throw ValidationException('operationId is required');
    }
    final code = command.code.trim();
    if (!_sixDigitCode.hasMatch(code)) {
      throw ValidationException('code must be a 6-digit number');
    }
  }
}
