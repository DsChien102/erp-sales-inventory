/// Field-level validation error for product custom field values.
final class CustomFieldValueValidationErrorDto {
  const CustomFieldValueValidationErrorDto({
    required this.fieldId,
    this.groupId,
    required this.code,
    required this.message,
  });

  final String fieldId;
  final String? groupId;
  final String code;
  final String message;
}
