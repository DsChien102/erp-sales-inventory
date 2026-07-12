import 'product_custom_field_snapshot_field_dto.dart';

final class ProductCustomFieldSnapshotDto {
  const ProductCustomFieldSnapshotDto({required this.products});

  final Map<String, List<ProductCustomFieldSnapshotFieldDto>> products;
}
