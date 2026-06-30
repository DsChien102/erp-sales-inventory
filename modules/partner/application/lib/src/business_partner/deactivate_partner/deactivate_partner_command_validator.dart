import 'package:vet45_shared_application/application.dart';

import 'deactivate_partner_command.dart';

final class DeactivatePartnerCommandValidator
    implements ICommandValidator<DeactivatePartnerCommand> {
  static const _maxStatusNoteLength = 1000;

  @override
  Future<void> validate(DeactivatePartnerCommand command) async {
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
    final note = command.statusNote?.trim();
    if (note != null && note.length > _maxStatusNoteLength) {
      throw ApplicationException('Status note is too long.');
    }
  }
}
