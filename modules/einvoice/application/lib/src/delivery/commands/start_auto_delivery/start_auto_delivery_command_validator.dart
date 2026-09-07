import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import 'start_auto_delivery_command.dart';

final class StartAutoDeliveryCommandValidator
    implements ICommandValidator<StartAutoDeliveryCommand> {
  @override
  Future<void> validate(StartAutoDeliveryCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.electronicInvoiceId.trim().isEmpty) {
      throw ValidationException('electronicInvoiceId is required');
    }
    if (command.triggerId.trim().isEmpty) {
      throw ValidationException('triggerId is required');
    }
    if (!Uuid.isValidUUID(fromString: command.idempotencyKey)) {
      throw ValidationException('idempotencyKey must be a canonical UUID');
    }
  }
}
