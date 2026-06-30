import 'package:vet45_shared_application/application.dart';

import 'register_partner_command.dart';

final class RegisterPartnerCommandValidator
    implements ICommandValidator<RegisterPartnerCommand> {
  @override
  Future<void> validate(RegisterPartnerCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ApplicationException('Tenant id is required.');
    }
    if (command.actorId.trim().isEmpty) {
      throw ApplicationException('Actor id is required.');
    }
    if (command.roles.isEmpty) {
      throw ApplicationException('At least one partner role is required.');
    }
    if (command.displayName.trim().isEmpty) {
      throw ApplicationException('Display name is required.');
    }
    if (command.phone.trim().isEmpty) {
      throw ApplicationException('Phone number is required.');
    }
  }
}
