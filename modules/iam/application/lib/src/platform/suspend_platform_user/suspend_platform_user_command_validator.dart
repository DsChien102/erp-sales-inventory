import 'package:vet45_shared_application/application.dart';

import 'suspend_platform_user_command.dart';

final class SuspendPlatformUserCommandValidator
    implements ICommandValidator<SuspendPlatformUserCommand> {
  @override
  Future<void> validate(SuspendPlatformUserCommand command) async {
    if (command.reason.trim().isEmpty) {
      throw ValidationException('Suspend reason is required');
    }
  }
}
