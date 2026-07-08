import 'package:vet45_shared_application/application.dart';

import 'create_product_command.dart';

final class CreateProductCommandValidator implements ICommandValidator<CreateProductCommand> {
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
    if (command.images.length > 8) {
      throw ValidationException('A product can have at most 8 images.');
    }
    final primaryCount = command.images.where((image) => image.isPrimary).length;
    if (primaryCount > 1) {
      throw ValidationException('Only one primary image is allowed.');
    }
  }
}
