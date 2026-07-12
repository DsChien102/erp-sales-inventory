/// Value mutation input for one product custom field.
final class ProductCustomFieldValueInput {
  const ProductCustomFieldValueInput({
    required this.fieldId,
    this.textValue,
    this.numberValue,
    this.dateValue,
    this.booleanValue,
    this.optionId,
  });

  final String fieldId;
  final String? textValue;
  final double? numberValue;
  final DateTime? dateValue;
  final bool? booleanValue;
  final String? optionId;

  bool get isEmpty =>
      (textValue == null || textValue!.trim().isEmpty) &&
      numberValue == null &&
      dateValue == null &&
      booleanValue == null &&
      (optionId == null || optionId!.trim().isEmpty);
}
