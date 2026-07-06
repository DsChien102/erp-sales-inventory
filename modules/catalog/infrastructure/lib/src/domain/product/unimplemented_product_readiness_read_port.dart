import 'package:vet45_catalog_application/application.dart';

/// CONTRACT stub — BE lane replaces with Supabase gateway.
final class UnimplementedProductReadinessReadPort
    implements IProductReadinessReadPort {
  const UnimplementedProductReadinessReadPort();

  @override
  Future<ProductReadinessViewDto> getByProductId({
    required String tenantId,
    required String productId,
  }) {
    throw UnimplementedError(
      'GetProductReadinessQuery BE lane not implemented (catalog.get_product_readiness)',
    );
  }
}
