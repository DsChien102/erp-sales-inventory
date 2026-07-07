import 'package:vet45_shared_domain/shared_kernel_domain.dart';

final class CustomFieldFilterCriteria extends ValueObject {
  CustomFieldFilterCriteria({
    required this.fieldId,
    this.optionId,
    this.textValue,
    this.numberValue,
    this.booleanValue,
    this.dateValue,
  });

  final String fieldId;
  final String? optionId;
  final String? textValue;
  final double? numberValue;
  final bool? booleanValue;
  final DateTime? dateValue;

  @override
  List<Object?> get props => [
    fieldId,
    optionId,
    textValue,
    numberValue,
    booleanValue,
    dateValue,
  ];
}
