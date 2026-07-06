import '../readiness/product_readiness_view_dto.dart';

/// Read port for product readiness view (BE lane: gateway + RPC).
abstract interface class IProductReadinessReadPort {
  Future<ProductReadinessViewDto> getByProductId({
    required String tenantId,
    required String productId,
  });
}
