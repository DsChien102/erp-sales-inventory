import 'package:vet45_shared_application/application.dart';

import 'record_delivery_result_command.dart';

final class RecordDeliveryResultCommandValidator
    implements ICommandValidator<RecordDeliveryResultCommand> {
  @override
  Future<void> validate(RecordDeliveryResultCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('tenantId is required');
    }
    if (command.deliveryId.trim().isEmpty) {
      throw ValidationException('deliveryId is required');
    }
    if (command.retryCount < 0 || command.retryCount > 2) {
      throw ValidationException('retryCount must be between 0 and 2');
    }
  }
}
