final class CustomFieldListValueDto {
  const CustomFieldListValueDto({
    required this.fieldId,
    required this.groupId,
    required this.groupName,
    required this.fieldName,
    required this.fieldType,
    required this.displayValue,
    required this.sortOrder,
  });

  final String fieldId;
  final String groupId;
  final String groupName;
  final String fieldName;
  final String fieldType;
  final String displayValue;
  final int sortOrder;
}
