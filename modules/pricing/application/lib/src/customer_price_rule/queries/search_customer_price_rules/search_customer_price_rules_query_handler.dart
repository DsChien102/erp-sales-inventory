import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_pricing_read_gateway.dart';
import 'customer_price_rule_search_result_dto.dart';
import 'search_customer_price_rules_query.dart';
import 'search_customer_price_rules_query_validator.dart';

@QueryHandlerFor(SearchCustomerPriceRulesQuery)
final class SearchCustomerPriceRulesQueryHandler
    implements
        IQueryHandler<
          SearchCustomerPriceRulesQuery,
          CustomerPriceRuleSearchResultDto
        > {
  SearchCustomerPriceRulesQueryHandler({
    required IPricingReadGateway readGateway,
    required SearchCustomerPriceRulesQueryValidator validator,
  }) : _readGateway = readGateway,
       _validator = validator;

  final IPricingReadGateway _readGateway;
  final SearchCustomerPriceRulesQueryValidator _validator;

  @override
  Future<CustomerPriceRuleSearchResultDto> handle(
    SearchCustomerPriceRulesQuery query,
  ) async {
    await _validator.validate(query);
    return _readGateway.searchCustomerPriceRules(query);
  }
}
