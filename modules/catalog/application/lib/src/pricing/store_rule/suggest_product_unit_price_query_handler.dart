import 'package:vet45_shared_application/application.dart';

import '../../ports/i_store_price_rule_gateway.dart';
import 'product_unit_price_suggestion_dto.dart';
import 'suggest_product_unit_price_query.dart';
import 'suggest_product_unit_price_query_validator.dart';

@QueryHandlerFor(SuggestProductUnitPriceQuery)
final class SuggestProductUnitPriceQueryHandler
    implements
        IQueryHandler<SuggestProductUnitPriceQuery, ProductUnitPriceSuggestionDto> {
  SuggestProductUnitPriceQueryHandler({
    required IStorePriceRuleGateway storePriceRuleGateway,
    SuggestProductUnitPriceQueryValidator? validator,
  }) : _storePriceRuleGateway = storePriceRuleGateway,
       _validator = validator ?? SuggestProductUnitPriceQueryValidator();

  final IStorePriceRuleGateway _storePriceRuleGateway;
  final SuggestProductUnitPriceQueryValidator _validator;

  @override
  Future<ProductUnitPriceSuggestionDto> handle(
    SuggestProductUnitPriceQuery query,
  ) async {
    await _validator.validate(query);
    return _storePriceRuleGateway.suggest(query: query);
  }
}
