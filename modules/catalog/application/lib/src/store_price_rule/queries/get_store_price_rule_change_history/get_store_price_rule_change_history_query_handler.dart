import 'package:vet45_shared_application/application.dart';

import 'package:vet45_catalog_application/src/ports/i_store_price_rule_gateway.dart';
import 'package:vet45_catalog_application/src/store_price_rule/queries/get_store_price_rule_change_history/store_price_rule_change_history_result_dto.dart';
import 'get_store_price_rule_change_history_query.dart';
import 'get_store_price_rule_change_history_query_validator.dart';

@QueryHandlerFor(GetStorePriceRuleChangeHistoryQuery)
final class GetStorePriceRuleChangeHistoryQueryHandler
    implements
        IQueryHandler<GetStorePriceRuleChangeHistoryQuery, StorePriceRuleChangeHistoryResultDto> {
  GetStorePriceRuleChangeHistoryQueryHandler({
    required IStorePriceRuleGateway storePriceRuleGateway,
    GetStorePriceRuleChangeHistoryQueryValidator? validator,
  }) : _storePriceRuleGateway = storePriceRuleGateway,
       _validator = validator ?? GetStorePriceRuleChangeHistoryQueryValidator();

  final IStorePriceRuleGateway _storePriceRuleGateway;
  final GetStorePriceRuleChangeHistoryQueryValidator _validator;

  @override
  Future<StorePriceRuleChangeHistoryResultDto> handle(
    GetStorePriceRuleChangeHistoryQuery query,
  ) async {
    await _validator.validate(query);
    return _storePriceRuleGateway.listChangeHistory(
      tenantId: query.tenantId,
      limit: query.limit,
      offset: query.offset,
    );
  }
}
