import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_pricing_read_gateway.dart';
import 'resolve_applicable_customer_price_rule_query.dart';
import 'resolve_applicable_customer_price_rule_query_validator.dart';
import 'resolve_applicable_customer_price_rule_result_dto.dart';

@QueryHandlerFor(ResolveApplicableCustomerPriceRuleQuery)
final class ResolveApplicableCustomerPriceRuleQueryHandler
    implements
        IQueryHandler<
          ResolveApplicableCustomerPriceRuleQuery,
          ResolveApplicableCustomerPriceRuleResultDto
        > {
  ResolveApplicableCustomerPriceRuleQueryHandler({
    required IPricingReadGateway readGateway,
    required ResolveApplicableCustomerPriceRuleQueryValidator validator,
  }) : _readGateway = readGateway,
       _validator = validator;

  final IPricingReadGateway _readGateway;
  final ResolveApplicableCustomerPriceRuleQueryValidator _validator;

  @override
  Future<ResolveApplicableCustomerPriceRuleResultDto> handle(
    ResolveApplicableCustomerPriceRuleQuery query,
  ) async {
    await _validator.validate(query);
    return _readGateway.resolveApplicableCustomerPriceRule(query);
  }
}
