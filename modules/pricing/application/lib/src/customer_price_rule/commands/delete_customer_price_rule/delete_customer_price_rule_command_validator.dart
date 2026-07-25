import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/pricing_blocked_codes.dart';
import '../../../shared/pricing_blocked_exception.dart';
import 'delete_customer_price_rule_command.dart';

final class DeleteCustomerPriceRuleCommandValidator
    implements ICommandValidator<DeleteCustomerPriceRuleCommand> {
  @override
  Future<void> validate(DeleteCustomerPriceRuleCommand command) async {
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
    if (fieldErrors.isNotEmpty) {
      throw PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid customer price rule delete payload.',
        details: {'fieldErrors': fieldErrors},
      );
    }
  }
}
