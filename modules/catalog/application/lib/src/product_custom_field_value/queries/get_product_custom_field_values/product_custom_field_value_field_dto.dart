import 'package:vet45_catalog_application/src/custom_field/shared/custom_field_select_option_dto.dart';

/// Product value row for a configured custom field.
final class ProductCustomFieldValueFieldDto {
  const ProductCustomFieldValueFieldDto({
    required this.fieldId,
    required this.groupId,
    required this.name,
    required this.fieldType,
    this.options = const [],
    this.isRequired = false,
    this.isMissing = false,
    this.sortOrder = 0,
    this.displayValue,
    this.textValue,
    this.numberValue,
    this.dateValue,
    this.booleanValue,
    this.optionId,
    this.isActive = true,
  });

  final String fieldId;
  final String groupId;
  final String name;
  final String fieldType;
  final List<CustomFieldSelectOptionDto> options;
  final bool isRequired;
  final bool isMissing;
  final int sortOrder;
  final String? displayValue;
  final String? textValue;
  final double? numberValue;
  final DateTime? dateValue;
  final bool? booleanValue;
  final String? optionId;
  final bool isActive;
}
