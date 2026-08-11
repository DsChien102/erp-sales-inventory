import 'package:vet45_shared_application/application.dart';

import 'verify_password_reset_by_email_command.dart';

final class VerifyPasswordResetByEmailCommandValidator
    implements ICommandValidator<VerifyPasswordResetByEmailCommand> {
  static final _sixDigitCode = RegExp(r'^\d{6}$');

  @override
  Future<void> validate(VerifyPasswordResetByEmailCommand command) async {
    if (command.operationId.trim().isEmpty) {
      throw ValidationException('operationId is required');
    }
    if (!_sixDigitCode.hasMatch(command.code.trim())) {
      throw ValidationException('code must be a 6-digit number');
    }
  }
}
