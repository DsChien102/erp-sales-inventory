import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/pricing_blocked_codes.dart';
import '../../../shared/pricing_blocked_exception.dart';
import 'disable_customer_price_rule_command.dart';

final class DisableCustomerPriceRuleCommandValidator
    implements ICommandValidator<DisableCustomerPriceRuleCommand> {
  @override
  Future<void> validate(DisableCustomerPriceRuleCommand command) async {
    final fieldErrors = <String, String>{};
    if (command.tenantId.trim().isEmpty) fieldErrors['tenantId'] = 'required';
    if (command.actorId.trim().isEmpty) fieldErrors['actorId'] = 'required';
    final ruleId = command.ruleId.trim();
    if (ruleId.isEmpty) {
      fieldErrors['ruleId'] = 'required';
    } else if (!Uuid.isValidUUID(fromString: ruleId)) {
      fieldErrors['ruleId'] = 'invalid';
    }
    if (command.expectedVersion <= 0) {
      fieldErrors['expectedVersion'] = 'must_be_positive';
    }
    if ((command.reason?.trim().length ?? 0) > 500) {
      fieldErrors['reason'] = 'too_long';
    }
    if (fieldErrors.isNotEmpty) {
      throw PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid customer price rule disable payload.',
        details: {'fieldErrors': fieldErrors},
      );
    }
  }
}
