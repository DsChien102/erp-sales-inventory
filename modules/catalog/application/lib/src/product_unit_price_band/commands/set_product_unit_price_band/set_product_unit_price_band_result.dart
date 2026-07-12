import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';
import 'package:vet45_catalog_application/src/product_unit_price_band/queries/list_product_unit_price_bands/price_band_source_type.dart';
import 'package:vet45_catalog_application/src/product_unit_price_band/shared/price_band_validation_warning_dto.dart';

final class SetProductUnitPriceBandResult {
  const SetProductUnitPriceBandResult({
    required this.productId,
    required this.listPrice,
    required this.floorPrice,
    required this.sourceType,
    required this.readinessSummary,
    this.productUnitId,
    this.storePriceRuleId,
    this.warnings = const [],
  });

  final String productId;
  final String? productUnitId;
  final double listPrice;
  final double floorPrice;
  final PriceBandSourceType sourceType;
  final String? storePriceRuleId;
  final List<PriceBandValidationWarningDto> warnings;
  final ReadinessSummaryDto readinessSummary;
}
