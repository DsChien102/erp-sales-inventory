import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import 'retry_issuance_command.dart';

final class RetryIssuanceCommandValidator implements ICommandValidator<RetryIssuanceCommand> {
  @override
  Future<void> validate(RetryIssuanceCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.actorId.trim().isEmpty) {
      throw ValidationException('actorId is required');
    }
    if (command.salesOrderId.trim().isEmpty) {
      throw ValidationException('salesOrderId is required');
    }
    if (command.expectedOrderVersion <= 0) {
      throw ValidationException('expectedOrderVersion must be positive');
    }
    if (!Uuid.isValidUUID(fromString: command.idempotencyKey)) {
      throw ValidationException('idempotencyKey must be a canonical UUID');
    }
  }
}
