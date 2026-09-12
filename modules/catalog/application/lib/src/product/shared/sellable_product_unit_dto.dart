final class SellableProductUnitDto {
  const SellableProductUnitDto({
    required this.productUnitId,
    required this.unitCode,
    required this.unitName,
    required this.barcode,
    required this.isDefault,
    required this.isActive,
    required this.isSellable,
    required this.blockReason,
    required this.listPriceMinor,
    required this.floorPriceMinor,
    required this.availableStockMicros,
  });

  final String productUnitId;
  final String unitCode;
  final String unitName;
  final String? barcode;
  final bool isDefault;
  final bool isActive;
  final bool isSellable;
  final String? blockReason;
  final int listPriceMinor;
  final int? floorPriceMinor;
  final int? availableStockMicros;
}
