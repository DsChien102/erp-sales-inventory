import 'package:vet45_catalog_domain/domain.dart';

/// Read port for product readiness facts (BE lane: gateway + RPC).
abstract interface class IProductReadinessReadPort {
  Future<ProductReadinessFacts?> loadFacts({
    required String tenantId,
    required String productId,
  });
}
