final class ProductCustomFieldSnapshotFieldDto {
  const ProductCustomFieldSnapshotFieldDto({
    required this.productId,
    required this.fieldId,
    required this.groupId,
    required this.groupName,
    required this.fieldName,
    required this.fieldType,
    this.displayValue,
    this.textValue,
    this.numberValue,
    this.dateValue,
    this.booleanValue,
    this.optionId,
    this.optionLabel,
    required this.isActive,
  });

  final String productId;
  final String fieldId;
  final String groupId;
  final String groupName;
  final String fieldName;
  final String fieldType;
  final String? displayValue;
  final String? textValue;
  final double? numberValue;
  final DateTime? dateValue;
  final bool? booleanValue;
  final String? optionId;
  final String? optionLabel;
  final bool isActive;
}
