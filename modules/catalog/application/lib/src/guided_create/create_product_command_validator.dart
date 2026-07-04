import 'package:vet45_shared_application/application.dart';

import 'create_product_command.dart';

final class CreateProductCommandValidator
    implements ICommandValidator<CreateProductCommand> {
  @override
  Future<void> validate(CreateProductCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.actorId.trim().isEmpty) {
      throw ValidationException('Actor id is required.');
    }
    if (command.productName.trim().isEmpty) {
      throw ValidationException('Product name is required.');
    }
  }
}
