import 'package:vet45_catalog_application/src/custom_field/shared/custom_field_select_option_dto.dart';

final class CustomFieldFilterOptionDto {
  const CustomFieldFilterOptionDto({
    required this.fieldId,
    required this.groupId,
    required this.groupName,
    required this.fieldName,
    required this.fieldType,
    required this.options,
    required this.sortOrder,
  });

  final String fieldId;
  final String groupId;
  final String groupName;
  final String fieldName;
  final String fieldType;
  final List<CustomFieldSelectOptionDto> options;
  final int sortOrder;
}
