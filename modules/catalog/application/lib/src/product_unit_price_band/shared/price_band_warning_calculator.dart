import 'package:vet45_catalog_application/src/product_unit/shared/product_unit_dto.dart';
import 'price_band_validation_field.dart';
import 'price_band_validation_warning_dto.dart';
import 'price_band_validation_warning_severity.dart';

abstract final class PriceBandWarningCalculator {
  static List<PriceBandValidationWarningDto> compute({
    required double? basePricePerBaseUnit,
    required String? baseUnitName,
    required ProductUnitDto unit,
    required double listPrice,
    required double floorPrice,
  }) {
    final comparableBase = _comparableBasePrice(
      basePricePerBaseUnit: basePricePerBaseUnit,
      unit: unit,
    );

    if (comparableBase == null) {
      if (!unit.isBaseUnit && basePricePerBaseUnit != null) {
        return [
          PriceBandValidationWarningDto(
            code: 'cannot_compare_base_price',
            severity: PriceBandValidationWarningSeverity.warning,
            message: 'Không thể so sánh chắc chắn với Giá cơ sở do thiếu tỷ lệ quy đổi.',
            field: PriceBandValidationField.listPrice,
            baseUnitName: baseUnitName,
          ),
        ];
      }
      return const [];
    }

    final warnings = <PriceBandValidationWarningDto>[];
    if (listPrice < comparableBase) {
      warnings.add(
        PriceBandValidationWarningDto(
          code: 'list_price_below_base_price',
          severity: PriceBandValidationWarningSeverity.warning,
          message: 'Giá niêm yết thấp hơn Giá cơ sở định giá.',
          field: PriceBandValidationField.listPrice,
          comparedBasePrice: comparableBase,
          baseUnitName: baseUnitName,
        ),
      );
    }
    if (floorPrice < comparableBase) {
      warnings.add(
        PriceBandValidationWarningDto(
          code: 'floor_price_below_base_price',
          severity: PriceBandValidationWarningSeverity.strongWarning,
          message: 'Giá sàn thấp hơn Giá cơ sở định giá.',
          field: PriceBandValidationField.floorPrice,
          comparedBasePrice: comparableBase,
          baseUnitName: baseUnitName,
        ),
      );
    }
    return warnings;
  }

  static double? _comparableBasePrice({
    required double? basePricePerBaseUnit,
    required ProductUnitDto unit,
  }) {
    if (basePricePerBaseUnit == null) {
      return null;
    }
    if (unit.isBaseUnit) {
      return basePricePerBaseUnit;
    }
    if (unit.conversionRateToBase <= 0) {
      return null;
    }
    return basePricePerBaseUnit * unit.conversionRateToBase;
  }
}
