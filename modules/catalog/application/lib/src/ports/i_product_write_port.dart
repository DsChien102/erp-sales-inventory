import 'package:vet45_catalog_domain/domain.dart';

/// Load product aggregate for write-side domain mutations.
abstract interface class IProductWritePort {
  Future<Product?> load({
    required String tenantId,
    required String productId,
  });
}
