import 'sellable_product_unit_dto.dart';

final class SellableProductDto {
  const SellableProductDto({
    required this.productId,
    required this.sku,
    required this.displayName,
    this.tradeName,
    required this.isSellable,
    required this.blockReason,
    required this.currencyCode,
    required this.listPriceMinor,
    required this.floorPriceMinor,
    required this.availableStockMicros,
    required this.units,
  });

  final String productId;
  final String? sku;
  final String displayName;
  final String? tradeName;
  final bool isSellable;
  final String? blockReason;
  final String currencyCode;
  final int listPriceMinor;
  final int? floorPriceMinor;
  final int? availableStockMicros;
  final List<SellableProductUnitDto> units;
}
