import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/pricing_blocked_codes.dart';
import '../../../shared/pricing_blocked_exception.dart';
import 'reenable_customer_price_rule_command.dart';

final class ReenableCustomerPriceRuleCommandValidator
    implements ICommandValidator<ReenableCustomerPriceRuleCommand> {
  static final _tokenPattern = RegExp(r'^[0-9a-f]{64}$');

  @override
  Future<void> validate(ReenableCustomerPriceRuleCommand command) async {
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
    if (command.precheckToken case final token?
        when !_tokenPattern.hasMatch(token)) {
      fieldErrors['precheckToken'] = 'invalid';
    }
    if (fieldErrors.isNotEmpty) {
      throw PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid customer price rule reenable payload.',
        details: {'fieldErrors': fieldErrors},
      );
    }
  }
}
