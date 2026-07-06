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
    if (command.listPrice < 0 || command.floorPrice < 0) {
      throw ValidationException('Giá không được âm.');
    }
    if (command.floorPrice > command.listPrice) {
      throw FloorPriceGreaterThanListPriceException();
    }
  }
}
