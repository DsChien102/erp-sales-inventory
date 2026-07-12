import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';
import 'package:vet45_catalog_application/src/product_custom_field_value/queries/get_product_custom_field_values/product_custom_field_values_dto.dart';

/// Result after saving product custom field values.
final class UpsertCustomFieldValuesResult {
  const UpsertCustomFieldValuesResult({
    required this.productId,
    required this.values,
    required this.readinessSummary,
  });

  final String productId;
  final ProductCustomFieldValuesDto values;
  final ReadinessSummaryDto readinessSummary;
}
