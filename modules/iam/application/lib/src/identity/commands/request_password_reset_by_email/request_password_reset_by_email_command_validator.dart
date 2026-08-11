import 'package:vet45_shared_application/application.dart';

import 'request_password_reset_by_email_command.dart';

final class RequestPasswordResetByEmailCommandValidator
    implements ICommandValidator<RequestPasswordResetByEmailCommand> {
  static final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  @override
  Future<void> validate(RequestPasswordResetByEmailCommand command) async {
    final email = command.email.trim();
    if (email.isEmpty || !_emailPattern.hasMatch(email)) {
      throw ValidationException('Valid email is required');
    }
  }
}
