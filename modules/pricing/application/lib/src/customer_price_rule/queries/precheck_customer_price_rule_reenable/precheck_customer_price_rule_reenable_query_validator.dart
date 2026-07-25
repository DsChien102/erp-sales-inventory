import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/pricing_blocked_codes.dart';
import '../../../shared/pricing_blocked_exception.dart';
import 'precheck_customer_price_rule_reenable_query.dart';

final class PrecheckCustomerPriceRuleReenableQueryValidator
    implements ICommandValidator<PrecheckCustomerPriceRuleReenableQuery> {
  @override
  Future<void> validate(PrecheckCustomerPriceRuleReenableQuery query) async {
    final fieldErrors = <String, String>{};
    if (query.tenantId.trim().isEmpty) fieldErrors['tenantId'] = 'required';
    final ruleId = query.ruleId.trim();
    if (ruleId.isEmpty) {
      fieldErrors['ruleId'] = 'required';
    } else if (!Uuid.isValidUUID(fromString: ruleId)) {
      fieldErrors['ruleId'] = 'invalid';
    }
    if (query.expectedVersion <= 0) {
      fieldErrors['expectedVersion'] = 'must_be_positive';
    }
    if (fieldErrors.isNotEmpty) {
      throw PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid customer price rule reenable precheck payload.',
        details: {'fieldErrors': fieldErrors},
      );
    }
  }
}
