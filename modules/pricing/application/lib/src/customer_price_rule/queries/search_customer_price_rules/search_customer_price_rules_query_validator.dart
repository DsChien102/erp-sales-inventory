import 'package:vet45_shared_application/application.dart';

import '../../../shared/pricing_blocked_codes.dart';
import '../../../shared/pricing_blocked_exception.dart';
import 'search_customer_price_rules_query.dart';

final class SearchCustomerPriceRulesQueryValidator
    implements ICommandValidator<SearchCustomerPriceRulesQuery> {
  @override
  Future<void> validate(SearchCustomerPriceRulesQuery query) async {
    final fieldErrors = <String, String>{};
    if (query.tenantId.trim().isEmpty) {
      fieldErrors['tenantId'] = 'required';
    }
    if (query.limit < 1 || query.limit > 100) {
      fieldErrors['limit'] = 'out_of_range';
    }
    if ((query.q?.length ?? 0) > 120) {
      fieldErrors['q'] = 'too_long';
    }
    if (query.customerId != null && query.customerId!.trim().isEmpty) {
      fieldErrors['customerId'] = 'blank';
    }
    if (query.productId != null && query.productId!.trim().isEmpty) {
      fieldErrors['productId'] = 'blank';
    }
    if (fieldErrors.isNotEmpty) {
      throw PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid customer price rule search payload.',
        details: {'fieldErrors': fieldErrors},
      );
    }
  }
}
