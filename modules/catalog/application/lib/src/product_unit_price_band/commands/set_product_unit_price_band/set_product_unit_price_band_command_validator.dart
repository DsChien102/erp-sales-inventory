import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'set_product_unit_price_band_command.dart';

final class SetProductUnitPriceBandCommandValidator
    implements ICommandValidator<SetProductUnitPriceBandCommand> {
  @override
  Future<void> validate(SetProductUnitPriceBandCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
    if (command.listBeforeVat < 0 || command.listAfterVat < 0) {
      throw ValidationException('Giá không được âm.');
    }
    final floorBefore = command.floorBeforeVat;
    if (floorBefore != null) {
      if (floorBefore < 0) {
        throw ValidationException('Giá không được âm.');
      }
      if (floorBefore > command.listBeforeVat) {
        throw FloorPriceGreaterThanListPriceException();
      }
    }
    final floorAfter = command.floorAfterVat;
    if (floorAfter != null) {
      if (floorAfter < 0) {
        throw ValidationException('Giá không được âm.');
      }
      if (floorAfter > command.listAfterVat) {
        throw FloorPriceGreaterThanListPriceException();
      }
    }
  }
}
