import 'package:vet45_catalog_application/src/custom_field/shared/custom_field_definition_dto.dart';

/// Result of configuring custom field attributes (EPIC-03/US-01/FR-05).
final class ConfigureCustomFieldAttributesResult {
  const ConfigureCustomFieldAttributesResult({
    required this.field,
    required this.existingProductsMissingCount,
  });

  final CustomFieldDefinitionDto field;
  final int existingProductsMissingCount;
}
