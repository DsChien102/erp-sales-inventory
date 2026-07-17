enum CustomerPriceRuleReferenceState { valid, inactive, missing }

enum CustomerPriceRulePriceBandState {
  current,
  currencyMismatch,
  invalidMinorUnits,
  unavailable,
}

final class CustomerPriceRuleReferenceHealthDto {
  const CustomerPriceRuleReferenceHealthDto({
    required this.customerState,
    required this.productUnitState,
    required this.priceBandState,
    required this.issueCodes,
    required this.usedStoredPriceBandSnapshot,
  });

  final CustomerPriceRuleReferenceState customerState;
  final CustomerPriceRuleReferenceState productUnitState;
  final CustomerPriceRulePriceBandState priceBandState;
  final List<String> issueCodes;
  final bool usedStoredPriceBandSnapshot;
}
