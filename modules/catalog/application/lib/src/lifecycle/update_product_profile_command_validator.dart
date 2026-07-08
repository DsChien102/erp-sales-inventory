import 'package:vet45_shared_application/application.dart';

import 'update_product_profile_command.dart';

final class UpdateProductProfileCommandValidator
    implements ICommandValidator<UpdateProductProfileCommand> {
  @override
  Future<void> validate(UpdateProductProfileCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.actorId.trim().isEmpty) {
      throw ValidationException('Actor id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
    if (command.productName.trim().isEmpty) {
      throw ValidationException('Product name is required.');
    }
    final expectedVersion = command.expectedVersion;
    if (expectedVersion != null && expectedVersion <= 0) {
      throw ValidationException('Expected version must be positive.');
    }
  }
}
