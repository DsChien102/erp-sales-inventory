import 'package:uuid/uuid.dart';
import 'package:vet45_shared_application/application.dart';

import '../../../shared/pricing_blocked_codes.dart';
import '../../../shared/pricing_blocked_exception.dart';
import 'get_customer_price_rule_history_query.dart';

final class GetCustomerPriceRuleHistoryQueryValidator
    implements ICommandValidator<GetCustomerPriceRuleHistoryQuery> {
  @override
  Future<void> validate(GetCustomerPriceRuleHistoryQuery query) async {
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
    if (query.limit < 1 || query.limit > 100) {
      fieldErrors['limit'] = 'out_of_range';
    }
    if ((query.cursor?.length ?? 0) > 1024) {
      fieldErrors['cursor'] = 'too_long';
    }
    if (fieldErrors.isNotEmpty) {
      throw PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid customer price rule history payload.',
        details: {'fieldErrors': fieldErrors},
      );
    }
  }
}
