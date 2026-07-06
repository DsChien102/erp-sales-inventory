import 'package:vet45_shared_application/application.dart';

import 'reactivate_product_conversion_unit_command.dart';

final class ReactivateProductConversionUnitCommandValidator
    implements ICommandValidator<ReactivateProductConversionUnitCommand> {
  @override
  Future<void> validate(ReactivateProductConversionUnitCommand command) async {
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
