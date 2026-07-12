import 'package:vet45_catalog_application/src/product_unit_price_band/commands/apply_store_price_rule/applied_store_price_rule_dto.dart';
import 'package:vet45_catalog_application/src/product_unit_price_band/commands/apply_store_price_rule/apply_store_price_rule_command.dart';
import 'package:vet45_catalog_application/src/product_unit_price_band/queries/suggest_product_unit_price/product_unit_price_suggestion_dto.dart';
import 'package:vet45_catalog_application/src/store_price_rule/queries/get_store_price_rule_change_history/store_price_rule_change_history_result_dto.dart';
import 'package:vet45_catalog_application/src/store_price_rule/shared/store_price_rule_dto.dart';
import 'package:vet45_catalog_application/src/store_price_rule/shared/store_price_rule_status.dart';
import 'package:vet45_catalog_application/src/product_unit_price_band/queries/suggest_product_unit_price/suggest_product_unit_price_query.dart';

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

  Future<StorePriceRuleChangeHistoryResultDto> listChangeHistory({
    required String tenantId,
    int limit = 50,
    int offset = 0,
  });
}
