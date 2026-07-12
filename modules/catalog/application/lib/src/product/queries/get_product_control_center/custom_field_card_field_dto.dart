/// Field row on a custom field group card (EPIC-01/US-02/FR-03).
final class CustomFieldCardFieldDto {
  const CustomFieldCardFieldDto({
    required this.fieldId,
    required this.name,
    required this.fieldType,
    this.displayValue,
    this.isRequired = false,
    this.isMissing = false,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final String fieldId;
  final String name;
  final String fieldType;
  final String? displayValue;
  final bool isRequired;
  final bool isMissing;
  final int sortOrder;
  final bool isActive;
}
