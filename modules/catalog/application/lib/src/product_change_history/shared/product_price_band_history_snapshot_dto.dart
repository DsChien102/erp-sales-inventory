import 'package:vet45_catalog_application/src/product_unit_price_band/queries/list_product_unit_price_bands/price_band_source_type.dart';

final class ProductPriceBandHistorySnapshotDto {
  const ProductPriceBandHistorySnapshotDto({
    required this.sourceType,
    required this.listPrice,
    this.floorPrice,
  });

  final PriceBandSourceType sourceType;
  final int listPrice;
  final int? floorPrice;
}
