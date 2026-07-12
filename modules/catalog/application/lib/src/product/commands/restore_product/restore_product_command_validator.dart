import 'package:vet45_shared_application/application.dart';

import 'restore_product_command.dart';

final class RestoreProductCommandValidator implements ICommandValidator<RestoreProductCommand> {
  @override
  Future<void> validate(RestoreProductCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.actorId.trim().isEmpty) {
      throw ValidationException('Actor id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
  }
}
