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
      if (command.listBeforeVat == null || command.listBeforeVat! < 0) {
        throw ValidationException('Giá niêm yết là bắt buộc và không được âm.');
      }
      final floor = command.floorBeforeVat;
      if (floor != null) {
        if (floor < 0) {
          throw ValidationException('Giá sàn không được âm.');
        }
        if (floor > command.listBeforeVat!) {
          throw FloorPriceGreaterThanListPriceException();
        }
      }
    }
  }
}
