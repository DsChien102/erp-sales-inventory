import 'package:vet45_shared_application/application.dart';

import '../../../../shared/pricing_blocked_codes.dart';
import '../../../../shared/pricing_blocked_exception.dart';
import 'get_customer_price_rule_import_template_query.dart';

final class GetCustomerPriceRuleImportTemplateQueryValidator
    implements ICommandValidator<GetCustomerPriceRuleImportTemplateQuery> {
  @override
  Future<void> validate(GetCustomerPriceRuleImportTemplateQuery query) async {
    if (query.tenantId.trim().isEmpty) {
      throw const PricingBlockedException(
        PricingBlockedCodes.validationError,
        message: 'Invalid import template query payload.',
        details: {
          'fieldErrors': {'tenantId': 'required'},
        },
      );
    }
  }
}
