import '../custom_fields/product_read/product_custom_field_snapshot_dto.dart';

abstract interface class ICatalogCustomFieldReadGateway {
  Future<ProductCustomFieldSnapshotDto> getSnapshot({
    required String tenantId,
    required List<String> productIds,
    required bool includeInactiveValues,
  });
}
