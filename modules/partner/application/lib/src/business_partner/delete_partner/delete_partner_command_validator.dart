import 'package:vet45_shared_application/application.dart';

import 'delete_partner_command.dart';

final class DeletePartnerCommandValidator
    implements ICommandValidator<DeletePartnerCommand> {
  @override
  Future<void> validate(DeletePartnerCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ApplicationException('Tenant id is required.');
    }
    if (command.actorId.trim().isEmpty) {
      throw ApplicationException('Actor id is required.');
    }
    if (command.partnerId.trim().isEmpty) {
      throw ApplicationException('Partner id is required.');
    }
    if (command.expectedVersion <= 0) {
      throw ApplicationException('Expected version is required.');
    }
  }
}
