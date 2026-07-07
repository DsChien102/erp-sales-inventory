import '../pricing/price_band/price_band_source_type.dart';
import '../pricing/price_band/product_unit_price_bands_dto.dart';
import '../pricing/price_band_snapshot/product_price_band_snapshot_dto.dart';
import '../pricing/price_band_snapshot/product_price_band_snapshot_request.dart';

abstract interface class IProductPriceBandGateway {
  Future<ProductUnitPriceBandsDto> listProductUnitPriceBands({
    required String tenantId,
    required String productId,
  });

  Future<ProductPriceBandSnapshotDto> getPriceBandSnapshot({
    required String tenantId,
    required List<ProductPriceBandSnapshotRequest> items,
  });

  Future<void> setProductUnitPriceBand({
    required String tenantId,
    required String productId,
    required String productUnitId,
    required double listPrice,
    required double floorPrice,
    required PriceBandSourceType sourceType,
    String? storePriceRuleId,
  });
}
