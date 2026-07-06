import 'package:vet45_shared_application/application.dart';

import 'adjust_basic_stock_command.dart';

final class AdjustBasicStockCommandValidator
    implements ICommandValidator<AdjustBasicStockCommand> {
  @override
  Future<void> validate(AdjustBasicStockCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
    if (command.newQuantity < 0) {
      throw ValidationException('Số lượng tồn kho không được âm.');
    }
  }
}
