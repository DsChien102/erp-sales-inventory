import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_pricing_read_gateway.dart';
import '../../shared/customer_price_rule_detail_dto.dart';
import 'get_customer_price_rule_detail_query.dart';
import 'get_customer_price_rule_detail_query_validator.dart';

@QueryHandlerFor(GetCustomerPriceRuleDetailQuery)
final class GetCustomerPriceRuleDetailQueryHandler
    implements
        IQueryHandler<
          GetCustomerPriceRuleDetailQuery,
          CustomerPriceRuleDetailDto
        > {
  GetCustomerPriceRuleDetailQueryHandler({
    required IPricingReadGateway readGateway,
    required GetCustomerPriceRuleDetailQueryValidator validator,
  }) : _readGateway = readGateway,
       _validator = validator;

  final IPricingReadGateway _readGateway;
  final GetCustomerPriceRuleDetailQueryValidator _validator;

  @override
  Future<CustomerPriceRuleDetailDto> handle(
    GetCustomerPriceRuleDetailQuery query,
  ) async {
    await _validator.validate(query);
    return _readGateway.getCustomerPriceRuleDetail(query);
  }
}
