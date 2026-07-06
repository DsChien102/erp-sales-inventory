import '../pricing/store_rule/applied_store_price_rule_dto.dart';
import '../pricing/store_rule/apply_store_price_rule_command.dart';
import '../pricing/store_rule/product_unit_price_suggestion_dto.dart';
import '../pricing/store_rule/store_price_rule_dto.dart';
import '../pricing/store_rule/store_price_rule_status.dart';
import '../pricing/store_rule/suggest_product_unit_price_query.dart';

abstract interface class IStorePriceRuleGateway {
  Future<StorePriceRuleDto?> getRule({required String tenantId});

  Future<StorePriceRuleDto> upsertRule({
    required String tenantId,
    required String name,
    required double listMarkupRatio,
    required double floorMarkupRatio,
    StorePriceRuleStatus status = StorePriceRuleStatus.active,
  });

  Future<ProductUnitPriceSuggestionDto> suggest({
    required SuggestProductUnitPriceQuery query,
  });

  Future<AppliedStorePriceRuleDto> apply({
    required ApplyStorePriceRuleCommand command,
  });
}
