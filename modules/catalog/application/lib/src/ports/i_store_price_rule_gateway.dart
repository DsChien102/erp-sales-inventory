import '../pricing/store_rule/store_price_calculation_type.dart';
import '../pricing/store_rule/store_price_rule_dto.dart';
import '../pricing/store_rule/store_price_rule_status.dart';

abstract interface class IStorePriceRuleGateway {
  Future<StorePriceRuleDto?> getRule({required String tenantId});

  Future<StorePriceRuleDto> upsertRule({
    required String tenantId,
    required String name,
    required double listMarkupRatio,
    required double floorMarkupRatio,
    StorePriceRuleStatus status = StorePriceRuleStatus.active,
  });
}
