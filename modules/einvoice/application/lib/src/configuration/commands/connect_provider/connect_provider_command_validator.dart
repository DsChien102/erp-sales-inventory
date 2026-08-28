import 'package:vet45_shared_application/application.dart';

import 'connect_provider_command.dart';

final class ConnectProviderCommandValidator implements ICommandValidator<ConnectProviderCommand> {
  @override
  Future<void> validate(ConnectProviderCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.actorId.trim().isEmpty) {
      throw ValidationException('actorId is required');
    }
    if (command.username.trim().isEmpty) {
      throw ValidationException('username is required');
    }
    if (command.password.isEmpty) {
      throw ValidationException('password is required');
    }
  }
}
