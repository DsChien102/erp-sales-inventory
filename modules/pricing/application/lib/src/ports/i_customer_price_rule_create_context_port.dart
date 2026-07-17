import '../customer_price_rule/commands/create_customer_price_rule/create_customer_price_rule_command.dart';
import '../customer_price_rule/shared/customer_price_rule_create_context.dart';

abstract interface class ICustomerPriceRuleCreateContextPort {
  Future<CustomerPriceRuleCreateContext> load(
    CreateCustomerPriceRuleCommand command,
  );
}
