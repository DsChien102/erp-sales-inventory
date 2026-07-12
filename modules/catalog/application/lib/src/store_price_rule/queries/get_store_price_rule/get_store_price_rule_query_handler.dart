import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_store_price_rule_gateway.dart';
import 'get_store_price_rule_query.dart';
import 'package:vet45_catalog_application/src/store_price_rule/shared/store_price_rule_dto.dart';

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
