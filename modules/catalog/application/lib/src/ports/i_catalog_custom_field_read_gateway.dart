import 'package:vet45_catalog_application/src/product_custom_field_value/queries/get_product_custom_field_snapshot/product_custom_field_snapshot_dto.dart';

abstract interface class ICatalogCustomFieldReadGateway {
  Future<ProductCustomFieldSnapshotDto> getSnapshot({
    required String tenantId,
    required List<String> productIds,
    required bool includeInactiveValues,
  });
}
