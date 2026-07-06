import 'package:vet45_shared_application/application.dart';

import 'apply_store_price_rule_command.dart';

final class ApplyStorePriceRuleCommandValidator
    implements ICommandValidator<ApplyStorePriceRuleCommand> {
  @override
  Future<void> validate(ApplyStorePriceRuleCommand command) async {
    if (command.tenantId.trim().isEmpty) {
      throw ValidationException('Tenant id is required.');
    }
    if (command.productId.trim().isEmpty) {
      throw ValidationException('Product id is required.');
    }
  }
}
