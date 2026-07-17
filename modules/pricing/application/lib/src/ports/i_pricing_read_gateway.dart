import '../customer_price_rule/queries/get_customer_price_rule_detail/get_customer_price_rule_detail_query.dart';
import '../customer_price_rule/queries/get_customer_price_rule_history/customer_price_rule_activity_dto.dart';
import '../customer_price_rule/queries/get_customer_price_rule_history/get_customer_price_rule_history_query.dart';
import '../customer_price_rule/queries/search_customer_price_rules/customer_price_rule_search_result_dto.dart';
import '../customer_price_rule/queries/search_customer_price_rules/search_customer_price_rules_query.dart';
import '../customer_price_rule/shared/cursor_page_dto.dart';
import '../customer_price_rule/shared/customer_price_rule_detail_dto.dart';

abstract interface class IPricingReadGateway {
  Future<CustomerPriceRuleSearchResultDto> searchCustomerPriceRules(
    SearchCustomerPriceRulesQuery query,
  );

  Future<CustomerPriceRuleDetailDto> getCustomerPriceRuleDetail(
    GetCustomerPriceRuleDetailQuery query,
  );

  Future<CursorPageDto<CustomerPriceRuleActivityDto>>
  getCustomerPriceRuleHistory(GetCustomerPriceRuleHistoryQuery query);
}
