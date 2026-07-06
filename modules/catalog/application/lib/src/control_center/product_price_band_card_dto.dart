/// Price band card on Product Control Center (EPIC-01/US-02/FR-02).
final class ProductPriceBandCardDto {
  const ProductPriceBandCardDto({
    this.listPrice,
    this.floorPrice,
    this.unitName,
    this.isMissing = false,
    this.missingMessage,
  });

  final double? listPrice;
  final double? floorPrice;
  final String? unitName;
  final bool isMissing;
  final String? missingMessage;
}
