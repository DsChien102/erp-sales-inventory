import 'package:vet45_catalog_domain/domain.dart';
import 'package:vet45_shared_application/application.dart';

import 'set_basic_stock_quantity_base_command.dart';

final class SetBasicStockQuantityBaseCommandValidator
    implements ICommandValidator<SetBasicStockQuantityBaseCommand> {
  @override
  Future<void> validate(SetBasicStockQuantityBaseCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
    if (command.quantity < 0) {
      throw ValidationException('Số lượng tồn kho ban đầu không được âm.');
    }
    if (command.mode != 'basic') {
      throw NotBasicStockModeException();
    }
  }
}
