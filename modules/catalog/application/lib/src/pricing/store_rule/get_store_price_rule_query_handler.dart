import 'package:vet45_shared_application/application.dart';

import '../../ports/i_store_price_rule_gateway.dart';
import 'get_store_price_rule_query.dart';
import 'store_price_rule_dto.dart';

@QueryHandlerFor(GetStorePriceRuleQuery)
final class GetStorePriceRuleQueryHandler
    implements IQueryHandler<GetStorePriceRuleQuery, StorePriceRuleDto?> {
  GetStorePriceRuleQueryHandler({
    required IStorePriceRuleGateway storePriceRuleGateway,
  }) : _storePriceRuleGateway = storePriceRuleGateway;

  final IStorePriceRuleGateway _storePriceRuleGateway;

  @override
  Future<StorePriceRuleDto?> handle(GetStorePriceRuleQuery query) {
    return _storePriceRuleGateway.getRule(tenantId: query.tenantId);
  }
}
