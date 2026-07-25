final class ProductPriceBandSnapshot {
  const ProductPriceBandSnapshot({
    required this.productId,
    required this.productName,
    required this.productUnitId,
    required this.unitName,
    required this.sellableStatus,
    required this.currencyCode,
    required this.floorPriceHidden,
    required this.isBelowFloor,
    this.listPriceMinor,
    this.floorPriceMinor,
  });

  final String productId;
  final String productName;
  final String productUnitId;
  final String unitName;
  final String sellableStatus;
  final String currencyCode;
  final int? listPriceMinor;
  final int? floorPriceMinor;
  final bool floorPriceHidden;
  final bool isBelowFloor;

  bool get isSellable => sellableStatus == 'active';
}
