import 'package:vet45_catalog_domain/domain.dart';

final class ProductPriceBandSnapshotItemDto {
  const ProductPriceBandSnapshotItemDto({
    required this.productId,
    required this.productUnitId,
    required this.unitName,
    required this.currency,
    required this.listPriceMissing,
    required this.floorPriceMissing,
    required this.floorPriceHidden,
    required this.isUnitActive,
    required this.productBusinessStatus,
    required this.capturedAt,
    this.listPrice,
    this.floorPrice,
  });

  final String productId;
  final String productUnitId;
  final String unitName;
  final String currency;
  final double? listPrice;
  final bool listPriceMissing;
  final double? floorPrice;
  final bool floorPriceMissing;
  final bool floorPriceHidden;
  final bool isUnitActive;
  final ProductBusinessStatus productBusinessStatus;
  final DateTime capturedAt;
}
