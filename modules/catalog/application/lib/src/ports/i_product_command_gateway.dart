import 'package:vet45_catalog_domain/domain.dart';

abstract interface class IProductCommandGateway {
  Future<String> create({
    required Product product,
    required String idempotencyKey,
  });

  Future<void> setInitialStock({
    required String productId,
    required String tenantId,
    required ProductStockProfile profile,
  });

  Future<void> setManualBasePrice({
    required String productId,
    required String tenantId,
    required ProductBasePriceProfile profile,
    String currency = 'VND',
  });

  Future<void> setInitialPriceBand({
    required String productId,
    required String tenantId,
    required ProductUnitPriceBand priceBand,
  });
}
