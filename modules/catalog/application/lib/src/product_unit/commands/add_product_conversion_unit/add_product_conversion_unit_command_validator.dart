import 'package:vet45_shared_application/application.dart';

import 'add_product_conversion_unit_command.dart';

final class AddProductConversionUnitCommandValidator
    implements ICommandValidator<AddProductConversionUnitCommand> {
  static const int maxUnitNameLength = 80;

  @override
  Future<void> validate(AddProductConversionUnitCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
    final unitName = command.unitName.trim();
    if (unitName.isEmpty) {
      throw ValidationException('Unit name must not be empty.');
    }
    if (unitName.length > maxUnitNameLength) {
      throw ValidationException('Unit name is too long.');
    }
    if (command.conversionRateToBase <= 0) {
      throw ValidationException('Conversion rate must be greater than zero.');
    }
  }
}
