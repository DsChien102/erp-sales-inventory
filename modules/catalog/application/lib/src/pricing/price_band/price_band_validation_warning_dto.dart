import 'price_band_validation_field.dart';
import 'price_band_validation_warning_severity.dart';

final class PriceBandValidationWarningDto {
  const PriceBandValidationWarningDto({
    required this.code,
    required this.severity,
    required this.message,
    required this.field,
    this.comparedBasePrice,
    this.baseUnitName,
  });

  final String code;
  final PriceBandValidationWarningSeverity severity;
  final String message;
  final PriceBandValidationField field;
  final double? comparedBasePrice;
  final String? baseUnitName;
}
