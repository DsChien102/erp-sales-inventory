final class ProductUnitPriceSuggestionDto {
  const ProductUnitPriceSuggestionDto({
    required this.productId,
    required this.basePrice,
    required this.currency,
    required this.canSuggest,
    this.productUnitId,
    this.unitName,
    this.suggestedListBeforeVat,
    this.suggestedFloorBeforeVat,
    this.storePriceRuleId,
    this.storePriceRuleName,
    this.basePriceVersion,
    this.unavailableReason,
  });

  final String productId;
  final String? productUnitId;
  final String? unitName;
  final double basePrice;
  final String currency;
  final int? suggestedListBeforeVat;
  final int? suggestedFloorBeforeVat;
  final String? storePriceRuleId;
  final String? storePriceRuleName;
  final int? basePriceVersion;
  final bool canSuggest;
  final String? unavailableReason;
}
