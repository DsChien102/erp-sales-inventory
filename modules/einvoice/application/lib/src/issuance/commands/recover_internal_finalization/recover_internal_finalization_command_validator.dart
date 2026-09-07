import 'package:vet45_shared_application/application.dart';

import 'recover_internal_finalization_command.dart';

final class RecoverInternalFinalizationCommandValidator
    implements ICommandValidator<RecoverInternalFinalizationCommand> {
  @override
  Future<void> validate(RecoverInternalFinalizationCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.attemptId.trim().isEmpty) {
      throw ValidationException('attemptId is required');
    }
  }
}
