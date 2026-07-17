import '../customer_price_rule/commands/update_customer_price_rule/update_customer_price_rule_command.dart';
import '../customer_price_rule/shared/customer_price_rule_update_context.dart';

abstract interface class ICustomerPriceRuleUpdateContextPort {
  Future<CustomerPriceRuleUpdateContext> load(
    UpdateCustomerPriceRuleCommand command,
  );
}
