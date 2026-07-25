import 'package:vet45_pricing_application/application.dart';

import 'customer_price_rule_detail_rpc_mapper.dart';

abstract final class PricingDisableRpcMapper {
  static Map<String, dynamic> params({
    required String tenantId,
    required String ruleId,
    required int expectedVersion,
    required String? reason,
  }) => {
    'p_tenant_id': tenantId,
    'p_rule_id': ruleId,
    'p_expected_version': expectedVersion,
    'p_reason': reason,
  };

  static CustomerPriceRuleDetailDto resultFromJson(Map<String, dynamic> json) =>
      CustomerPriceRuleDetailRpcMapper.detailFromJson(json);
}
