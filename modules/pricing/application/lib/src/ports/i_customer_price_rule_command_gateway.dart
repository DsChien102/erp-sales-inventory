import 'package:vet45_pricing_domain/domain.dart';

import '../customer_price_rule/commands/create_customer_price_rule/create_customer_price_rule_result.dart';
import '../customer_price_rule/shared/customer_price_rule_detail_dto.dart';

abstract interface class ICustomerPriceRuleCommandGateway {
  Future<CreateCustomerPriceRuleResult> create({
    required CustomerPriceRule candidate,
    required String idempotencyKey,
    required bool acknowledgeFloorWarning,
    bool acknowledgeOverwrite = false,
  });

  Future<CustomerPriceRuleDetailDto> update({
    required CustomerPriceRule candidate,
    required int expectedVersion,
    required bool acknowledgeFloorWarning,
    bool acknowledgeOverwrite = false,
  });

  Future<CustomerPriceRuleDetailDto> disable({
    required String tenantId,
    required String ruleId,
    required int expectedVersion,
    required String? reason,
  });

  Future<CustomerPriceRuleDetailDto> delete({
    required String tenantId,
    required String ruleId,
    required int expectedVersion,
  });

  Future<CustomerPriceRuleDetailDto> reenable({
    required String tenantId,
    required String ruleId,
    required int expectedVersion,
    required DateTime businessDate,
    required String? precheckToken,
    required bool acknowledgeFloorWarning,
  });
}
