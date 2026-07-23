import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/pricing_blocked_codes.dart';
import '../../../shared/pricing_blocked_exception.dart';
import 'update_customer_price_rule_command.dart';

final class UpdateCustomerPriceRuleCommandValidator
    implements ICommandValidator<UpdateCustomerPriceRuleCommand> {
  @override
  Future<void> validate(UpdateCustomerPriceRuleCommand command) async {
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
    if (command.rulePriceMinor <= 0) {
      fieldErrors['rulePriceMinor'] = 'must_be_positive';
    }
    if (command.effectiveTo != null &&
        _isCalendarDateBefore(
          command.effectiveTo!,
          command.effectiveFrom,
        )) {
      fieldErrors['effectiveTo'] = 'before_effective_from';
    }
    if (fieldErrors.isNotEmpty) {
      throw PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid customer price rule update payload.',
        details: {'fieldErrors': fieldErrors},
      );
    }
  }
}

/// Compare calendar Y/M/D only — ignores local vs UTC midnight of the same day.
bool _isCalendarDateBefore(DateTime a, DateTime b) {
  if (a.year != b.year) return a.year < b.year;
  if (a.month != b.month) return a.month < b.month;
  return a.day < b.day;
}
