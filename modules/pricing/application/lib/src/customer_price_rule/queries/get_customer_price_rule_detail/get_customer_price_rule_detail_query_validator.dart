import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/pricing_blocked_codes.dart';
import '../../../shared/pricing_blocked_exception.dart';
import 'get_customer_price_rule_detail_query.dart';

final class GetCustomerPriceRuleDetailQueryValidator
    implements ICommandValidator<GetCustomerPriceRuleDetailQuery> {
  @override
  Future<void> validate(GetCustomerPriceRuleDetailQuery query) async {
    final fieldErrors = <String, String>{};
    if (query.tenantId.trim().isEmpty) {
      fieldErrors['tenantId'] = 'required';
    }
    final ruleId = query.ruleId.trim();
    if (ruleId.isEmpty) {
      fieldErrors['ruleId'] = 'required';
    } else if (!Uuid.isValidUUID(fromString: ruleId)) {
      fieldErrors['ruleId'] = 'invalid';
    }
    if (fieldErrors.isNotEmpty) {
      throw PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid customer price rule detail payload.',
        details: {'fieldErrors': fieldErrors},
      );
    }
  }
}
