import 'custom_field_value_validation_error_dto.dart';

/// Validation failure that can be rendered on exact custom field inputs.
final class CustomFieldValueValidationException implements Exception {
  CustomFieldValueValidationException({required this.errors})
    : message = errors.map((error) => error.message).join('\n');

  final List<CustomFieldValueValidationErrorDto> errors;
  final String message;

  @override
  String toString() => message;
}
