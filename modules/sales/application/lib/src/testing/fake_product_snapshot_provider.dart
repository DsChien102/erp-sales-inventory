import '../ports/i_product_snapshot_provider.dart';
import '../shared/product_snapshot_dto.dart';
import '../shared/product_unit_snapshot_dto.dart';

final class FakeProductSnapshotProvider implements IProductSnapshotProvider {
  const FakeProductSnapshotProvider({this.product, this.unit});

  final ProductSnapshotDto? product;
  final ProductUnitSnapshotDto? unit;

  @override
  Future<ProductSnapshotDto?> getProductSnapshot({
    required String tenantId,
    required String productId,
  }) async => product;

  @override
  Future<ProductUnitSnapshotDto?> getUnitSnapshot({
    required String tenantId,
    required String productUnitId,
  }) async => unit;
}
