import 'package:vet45_shared_application/application.dart';

import '../../../ports/i_pricing_read_gateway.dart';
import '../../shared/cursor_page_dto.dart';
import 'customer_price_rule_activity_dto.dart';
import 'get_customer_price_rule_history_query.dart';
import 'get_customer_price_rule_history_query_validator.dart';

@QueryHandlerFor(GetCustomerPriceRuleHistoryQuery)
final class GetCustomerPriceRuleHistoryQueryHandler
    implements
        IQueryHandler<
          GetCustomerPriceRuleHistoryQuery,
          CursorPageDto<CustomerPriceRuleActivityDto>
        > {
  GetCustomerPriceRuleHistoryQueryHandler({
    required IPricingReadGateway readGateway,
    required GetCustomerPriceRuleHistoryQueryValidator validator,
  }) : _readGateway = readGateway,
       _validator = validator;

  final IPricingReadGateway _readGateway;
  final GetCustomerPriceRuleHistoryQueryValidator _validator;

  @override
  Future<CursorPageDto<CustomerPriceRuleActivityDto>> handle(
    GetCustomerPriceRuleHistoryQuery query,
  ) async {
    await _validator.validate(query);
    return _readGateway.getCustomerPriceRuleHistory(query);
  }
}
