import 'package:vet45_shared_domain/shared_kernel_domain.dart';

import 'rules/customer_price_rule_key_must_be_complete_rule.dart';

final class CustomerPriceRuleKey extends ValueObject {
  CustomerPriceRuleKey({
    required this.tenantId,
    required this.customerId,
    required this.productId,
    required this.productUnitId,
  }) {
    ValueObject.checkRule(
      CustomerPriceRuleKeyMustBeCompleteRule([
        tenantId,
        customerId,
        productId,
        productUnitId,
      ]),
    );
  }

  final String tenantId;
  final String customerId;
  final String productId;
  final String productUnitId;

  @override
  List<Object?> get props => [tenantId, customerId, productId, productUnitId];
}
