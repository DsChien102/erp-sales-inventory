final class SalesPricingLineInput {
  const SalesPricingLineInput({
    required this.localLineId,
    required this.productId,
    required this.productUnitId,
    required this.quantityMicros,
    this.manualUnitPriceMinor,
    this.manualDiscountMinor,
    this.manualDiscountBasisPoints,
  });

  final String localLineId;
  final String productId;
  final String productUnitId;
  final int quantityMicros;
  final int? manualUnitPriceMinor;
  final int? manualDiscountMinor;
  final int? manualDiscountBasisPoints;

  int get manualIntentCount => [
    manualUnitPriceMinor,
    manualDiscountMinor,
    manualDiscountBasisPoints,
  ].where((value) => value != null).length;
}
