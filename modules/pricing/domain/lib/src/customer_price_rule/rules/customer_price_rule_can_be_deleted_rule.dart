import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import '../customer_price_rule_status.dart';

final class CustomerPriceRuleCanBeDeletedRule implements IBusinessRule {
  const CustomerPriceRuleCanBeDeletedRule(this.status);

  final CustomerPriceRuleStatus status;

  @override
  bool isBroken() =>
      status != CustomerPriceRuleStatus.active &&
      status != CustomerPriceRuleStatus.needsReview;

  @override
  String get message =>
      'Customer price rule cannot be deleted in its current status.';
}
