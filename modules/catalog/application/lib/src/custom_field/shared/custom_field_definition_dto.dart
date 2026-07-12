import 'package:vet45_catalog_domain/domain.dart';

import 'custom_field_select_option_dto.dart';

/// Custom field definition in tenant config (EPIC-03/US-01).
final class CustomFieldDefinitionDto {
  const CustomFieldDefinitionDto({
    required this.fieldId,
    required this.groupId,
    required this.name,
    required this.fieldType,
    this.options = const [],
    this.isRequired = false,
    this.isSearchable = false,
    this.isFilterable = false,
    this.displayOnList = false,
    this.sortOrder = 0,
    this.status = CustomFieldConfigStatus.active,
    this.hasProductValues = false,
  });

  final String fieldId;
  final String groupId;
  final String name;
  final CustomFieldType fieldType;
  final List<CustomFieldSelectOptionDto> options;
  final bool isRequired;
  final bool isSearchable;
  final bool isFilterable;
  final bool displayOnList;
  final int sortOrder;
  final CustomFieldConfigStatus status;

  /// True when at least one [product_custom_field_values] row exists for this field.
  final bool hasProductValues;
}
