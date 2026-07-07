import '../custom_fields/product_values/product_custom_field_values_dto.dart';
import '../custom_fields/product_values/upsert_custom_field_values_command.dart';
import '../custom_fields/product_values/upsert_custom_field_values_result.dart';

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
