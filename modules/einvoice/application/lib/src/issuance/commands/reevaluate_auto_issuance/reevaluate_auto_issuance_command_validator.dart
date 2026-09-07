import 'package:vet45_shared_application/application.dart';

import 'reevaluate_auto_issuance_command.dart';

final class ReevaluateAutoIssuanceCommandValidator
    implements ICommandValidator<ReevaluateAutoIssuanceCommand> {
  @override
  Future<void> validate(ReevaluateAutoIssuanceCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.processId.trim().isEmpty) {
      throw ValidationException('processId is required');
    }
    if (command.sourceEventId.trim().isEmpty) {
      throw ValidationException('sourceEventId is required');
    }
  }
}
