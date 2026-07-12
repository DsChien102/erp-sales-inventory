import 'package:vet45_catalog_application/src/product_unit_price_band/queries/list_product_unit_price_bands/price_band_source_type.dart';
import 'package:vet45_catalog_application/src/product_unit_price_band/queries/list_product_unit_price_bands/product_unit_price_bands_dto.dart';
import 'package:vet45_catalog_application/src/product_unit_price_band/queries/get_product_price_band_snapshot/product_price_band_snapshot_dto.dart';
import 'package:vet45_catalog_application/src/product_unit_price_band/queries/get_product_price_band_snapshot/product_price_band_snapshot_request.dart';

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
