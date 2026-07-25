import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../customer_price_rule_status.dart';

final class CustomerPriceRuleCanBeReenabledRule implements IBusinessRule {
  const CustomerPriceRuleCanBeReenabledRule(this.status);

  final CustomerPriceRuleStatus status;

  @override
  bool isBroken() => status != CustomerPriceRuleStatus.disabled;

  @override
  String get message => 'Only a disabled customer price rule can be reenabled.';
}
