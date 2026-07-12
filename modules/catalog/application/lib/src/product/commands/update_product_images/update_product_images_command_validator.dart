import 'package:vet45_shared_application/application.dart';

import 'update_product_images_command.dart';

final class UpdateProductImagesCommandValidator
    implements ICommandValidator<UpdateProductImagesCommand> {
  @override
  Future<void> validate(UpdateProductImagesCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.actorId.trim().isEmpty) {
      throw ValidationException('Actor id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
    final expectedVersion = command.expectedVersion;
    if (expectedVersion != null && expectedVersion <= 0) {
      throw ValidationException('Expected version must be positive.');
    }
    if (command.images.where((image) => image.isPrimary).length > 1) {
      throw ValidationException('A product may have at most one primary image.');
    }
    for (final image in command.images) {
      if (image.storageKey.trim().isEmpty) {
        throw ValidationException('Image storage key is required.');
      }
    }
  }
}
