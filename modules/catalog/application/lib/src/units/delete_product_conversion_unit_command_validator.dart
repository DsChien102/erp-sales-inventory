import 'package:vet45_shared_application/application.dart';

import 'delete_product_conversion_unit_command.dart';

final class DeleteProductConversionUnitCommandValidator
    implements ICommandValidator<DeleteProductConversionUnitCommand> {
  @override
  Future<void> validate(DeleteProductConversionUnitCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
    if (command.productUnitId.trim().isEmpty) {
      throw ValidationException('Product unit id is required.');
    }
  }
}
