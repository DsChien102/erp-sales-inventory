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
    if (command.attemptId.trim().isEmpty) {
      throw ValidationException('attemptId is required');
    }
    if (command.interactionReference.trim().isEmpty) {
      throw ValidationException('interactionReference is required');
    }
  }
}
