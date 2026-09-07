import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import 'start_auto_issuance_command.dart';

final class StartAutoIssuanceCommandValidator
    implements ICommandValidator<StartAutoIssuanceCommand> {
  @override
  Future<void> validate(StartAutoIssuanceCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.salesOrderId.trim().isEmpty) {
      throw ValidationException('salesOrderId is required');
    }
    if (command.triggerKey.trim().isEmpty) {
      throw ValidationException('triggerKey is required');
    }
    if (!Uuid.isValidUUID(fromString: command.idempotencyKey)) {
      throw ValidationException('idempotencyKey must be a canonical UUID');
    }
  }
}
