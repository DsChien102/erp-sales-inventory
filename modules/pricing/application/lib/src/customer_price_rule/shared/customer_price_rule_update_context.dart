import 'package:vet45_pricing_domain/domain.dart';

import 'customer_snapshot.dart';
import 'product_price_band_snapshot.dart';

final class CustomerPriceRuleUpdateContext {
  const CustomerPriceRuleUpdateContext({
    required this.currentRule,
    required this.customer,
    required this.productUnit,
    required this.canOverrideFloor,
    this.hasConflictingRule = false,
    this.conflictingRuleId,
  });

  final CustomerPriceRule currentRule;
  final CustomerSnapshot customer;
  final ProductPriceBandSnapshot productUnit;
  final bool canOverrideFloor;
  final bool hasConflictingRule;
  final String? conflictingRuleId;
}
