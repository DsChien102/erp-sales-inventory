import 'package:vet45_catalog_application/src/product_custom_field_value/queries/get_product_custom_field_values/product_custom_field_values_dto.dart';
import 'package:vet45_catalog_application/src/product_custom_field_value/commands/upsert_custom_field_values/upsert_custom_field_values_command.dart';
import 'package:vet45_catalog_application/src/product_custom_field_value/commands/upsert_custom_field_values/upsert_custom_field_values_result.dart';

/// Port for product custom field values (EPIC-03/US-02).
abstract interface class ICatalogCustomFieldValueGateway {
  Future<ProductCustomFieldValuesDto> getValues({
    required String tenantId,
    required String productId,
    bool includeInactiveValues = false,
  });

  Future<UpsertCustomFieldValuesResult> upsertValues({
    required UpsertCustomFieldValuesCommand command,
  });
}
