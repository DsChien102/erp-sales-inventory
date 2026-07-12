import 'package:vet45_shared_application/application.dart';

import 'request_product_maintenance_image_upload_command.dart';

final class RequestProductMaintenanceImageUploadCommandValidator
    implements ICommandValidator<RequestProductMaintenanceImageUploadCommand> {
  static const _allowedContentTypes = {
    'image/jpeg',
    'image/png',
    'image/webp',
  };

  static const _maxByteSize = 10 * 1024 * 1024;

  @override
  Future<void> validate(RequestProductMaintenanceImageUploadCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.actorId.trim().isEmpty) {
      throw ValidationException('Actor id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
    if (command.fileName.trim().isEmpty) {
      throw ValidationException('File name is required.');
    }
    if (!_allowedContentTypes.contains(command.contentType.toLowerCase())) {
      throw ValidationException('Unsupported image content type.');
    }
    if (command.byteSize <= 0) {
      throw ValidationException('Image byte size must be positive.');
    }
    if (command.byteSize > _maxByteSize) {
      throw ValidationException('Image exceeds maximum allowed size.');
    }
  }
}
