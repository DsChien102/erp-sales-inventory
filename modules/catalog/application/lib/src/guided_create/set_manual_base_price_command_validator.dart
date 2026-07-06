import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'set_manual_base_price_command.dart';

final class SetManualBasePriceCommandValidator
    implements ICommandValidator<SetManualBasePriceCommand> {
  @override
  Future<void> validate(SetManualBasePriceCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
    if (command.basePrice < 0) {
      throw ValidationException('Giá vốn cơ sở không được âm.');
    }
    if (command.mode != 'manual') {
      throw NotManualBasePriceModeException();
    }
  }
}
