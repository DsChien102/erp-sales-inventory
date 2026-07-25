import '../customer_price_rule/queries/precheck_customer_price_rule_reenable/customer_price_rule_reenable_precheck_dto.dart';
import '../customer_price_rule/queries/precheck_customer_price_rule_reenable/precheck_customer_price_rule_reenable_query.dart';

abstract interface class ICustomerPriceRuleReenablePrecheckPort {
  Future<CustomerPriceRuleReenablePrecheckDto> precheck(
    PrecheckCustomerPriceRuleReenableQuery query,
  );
}
