import '../shared/product_snapshot_dto.dart';
import '../shared/product_unit_snapshot_dto.dart';

abstract interface class IProductSnapshotProvider {
  Future<ProductSnapshotDto?> getProductSnapshot({
    required String tenantId,
    required String productId,
  });

  Future<ProductUnitSnapshotDto?> getUnitSnapshot({
    required String tenantId,
    required String productUnitId,
  });
}
