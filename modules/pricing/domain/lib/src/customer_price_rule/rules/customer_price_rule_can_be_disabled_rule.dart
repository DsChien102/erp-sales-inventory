import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../customer_price_rule_status.dart';

final class CustomerPriceRuleCanBeDisabledRule implements IBusinessRule {
  const CustomerPriceRuleCanBeDisabledRule(this.status);

  final CustomerPriceRuleStatus status;

  @override
  bool isBroken() =>
      status != CustomerPriceRuleStatus.active &&
      status != CustomerPriceRuleStatus.needsReview;

  @override
  String get message =>
      'Customer price rule cannot be disabled in its current status.';
}
