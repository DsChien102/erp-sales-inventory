import 'package:vet45_shared_application/application.dart';

import 'update_partner_profile_command.dart';

final class UpdatePartnerProfileCommandValidator
    implements ICommandValidator<UpdatePartnerProfileCommand> {
  @override
  Future<void> validate(UpdatePartnerProfileCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ApplicationException('Tenant id is required.');
    }
    if (command.actorId.trim().isEmpty) {
      throw ApplicationException('Actor id is required.');
    }
    if (command.partnerId.trim().isEmpty) {
      throw ApplicationException('Partner id is required.');
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
