import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'set_initial_price_band_command.dart';

final class SetInitialPriceBandCommandValidator
    implements ICommandValidator<SetInitialPriceBandCommand> {
  @override
  Future<void> validate(SetInitialPriceBandCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }

    final useRule = command.useStoreRule ?? false;
    if (!useRule) {
      if (command.listPrice == null || command.listPrice! < 0) {
        throw ValidationException('Giá niêm yết là bắt buộc và không được âm.');
      }
      if (command.floorPrice == null || command.floorPrice! < 0) {
        throw ValidationException('Giá sàn là bắt buộc và không được âm.');
      }
      if (command.floorPrice! > command.listPrice!) {
        throw FloorPriceGreaterThanListPriceException();
      }
    }
  }
}
