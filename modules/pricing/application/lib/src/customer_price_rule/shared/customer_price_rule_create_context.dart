import 'customer_snapshot.dart';
import 'product_price_band_snapshot.dart';

final class CustomerPriceRuleCreateContext {
  const CustomerPriceRuleCreateContext({
    required this.customer,
    required this.productUnit,
    required this.canOverrideFloor,
    this.hasConflictingRule = false,
    this.idempotencyKeyExists = false,
    this.conflictingRuleId,
  });

  final CustomerSnapshot customer;
  final ProductPriceBandSnapshot productUnit;
  final bool canOverrideFloor;
  final bool hasConflictingRule;
  final bool idempotencyKeyExists;
  final String? conflictingRuleId;

  CustomerPriceRuleCreateContext copyWith({
    CustomerSnapshot? customer,
    ProductPriceBandSnapshot? productUnit,
    bool? canOverrideFloor,
    bool? hasConflictingRule,
    bool? idempotencyKeyExists,
    String? conflictingRuleId,
  }) => CustomerPriceRuleCreateContext(
    customer: customer ?? this.customer,
    productUnit: productUnit ?? this.productUnit,
    canOverrideFloor: canOverrideFloor ?? this.canOverrideFloor,
    hasConflictingRule:
        hasConflictingRule ??
        conflictingRuleId != null || this.hasConflictingRule,
    idempotencyKeyExists: idempotencyKeyExists ?? this.idempotencyKeyExists,
    conflictingRuleId: conflictingRuleId ?? this.conflictingRuleId,
  );
}
