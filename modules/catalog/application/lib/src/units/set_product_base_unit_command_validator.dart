import 'package:vet45_shared_application/application.dart';

import 'base_unit_selection.dart';
import 'set_product_base_unit_command.dart';

final class SetProductBaseUnitCommandValidator
    implements ICommandValidator<SetProductBaseUnitCommand> {
  static const int maxUnitNameLength = 80;

  @override
  Future<void> validate(SetProductBaseUnitCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }

    final selection = command.selection;
    switch (selection) {
      case ExistingTenantUnit(:final unitId):
        if (unitId.trim().isEmpty) {
          throw ValidationException('Measurement unit id is required.');
        }
      case NewTenantUnit(:final name):
        final trimmed = name.trim();
        if (trimmed.isEmpty) {
          throw ValidationException('Unit name must not be empty.');
        }
        if (trimmed.length > maxUnitNameLength) {
          throw ValidationException('Unit name is too long.');
        }
    }
  }
}
