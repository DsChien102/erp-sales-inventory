import 'package:vet45_shared_application/application.dart';

import '../../../../shared/pricing_blocked_codes.dart';
import '../../../../shared/pricing_blocked_exception.dart';
import 'cancel_customer_price_rule_import_command.dart';

final class CancelCustomerPriceRuleImportCommandValidator
    implements ICommandValidator<CancelCustomerPriceRuleImportCommand> {
  @override
  Future<void> validate(CancelCustomerPriceRuleImportCommand command) async {
    final fieldErrors = <String, String>{};
    for (final entry in {
      'tenantId': command.tenantId,
      'actorId': command.actorId,
      'importId': command.importId,
    }.entries) {
      if (entry.value.trim().isEmpty) {
        fieldErrors[entry.key] = 'required';
      }
    }
    if (command.expectedVersion <= 0) {
      fieldErrors['expectedVersion'] = 'must_be_positive';
    }
    if (fieldErrors.isNotEmpty) {
      throw PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid import cancel payload.',
        details: {'fieldErrors': fieldErrors},
      );
    }
  }
}
