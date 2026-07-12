import 'package:vet45_shared_application/application.dart';

import 'reactivate_product_command.dart';

final class ReactivateProductCommandValidator
    implements ICommandValidator<ReactivateProductCommand> {
  @override
  Future<void> validate(ReactivateProductCommand command) async {
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
