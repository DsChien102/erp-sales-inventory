import 'package:vet45_catalog_application/src/product/shared/sellable_product_dto.dart';
import 'package:vet45_catalog_application/src/product/shared/sellable_product_resolution_dto.dart';
import 'package:vet45_catalog_application/src/product/shared/sellable_product_unit_dto.dart';

abstract interface class ICatalogSalesReadGateway {
  Future<List<SellableProductDto>> searchSellableProducts({
    required String tenantId,
    required String storeId,
    required String keyword,
    required int limit,
    required int offset,
  });

  Future<List<SellableProductDto>> resolveSellableBarcode({
    required String tenantId,
    required String storeId,
    required String barcode,
  });

  Future<List<SellableProductUnitDto>> listSellableProductUnits({
    required String tenantId,
    required String storeId,
    required String productId,
  });

  /// Resolves each requested product id to an explicit outcome.
  ///
  /// Returns one entry per requested id, including ids that no longer exist or
  /// are no longer sellable, so callers never infer business meaning from an
  /// empty result.
  Future<List<SellableProductResolutionDto>> resolveSellableProducts({
    required String tenantId,
    required String storeId,
    required List<String> productIds,
  });
}
