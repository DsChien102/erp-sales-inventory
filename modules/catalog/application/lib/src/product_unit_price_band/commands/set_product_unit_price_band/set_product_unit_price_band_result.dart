import 'package:vet45_catalog_domain/domain.dart';

import 'package:vet45_catalog_application/src/shared/readiness_summary_dto.dart';
import 'package:vet45_catalog_application/src/product_unit_price_band/queries/list_product_unit_price_bands/price_band_source_type.dart';
import 'package:vet45_catalog_application/src/product_unit_price_band/shared/price_band_validation_warning_dto.dart';

final class SetProductUnitPriceBandResult {
  const SetProductUnitPriceBandResult({
    required this.productId,
    required this.listBeforeVat,
    required this.listAfterVat,
    required this.sourceType,
    required this.readinessSummary,
    this.floorBeforeVat,
    this.productUnitId,
    this.floorAfterVat,
    this.effectiveFrom,
    this.effectiveTo,
    this.status,
    this.storePriceRuleId,
    this.warnings = const [],
  });

  final String productId;
  final String? productUnitId;
  final int listBeforeVat;
  final int? floorBeforeVat;
  final int listAfterVat;
  final int? floorAfterVat;
  final DateTime? effectiveFrom;
  final DateTime? effectiveTo;
  final ProductPriceBandStatus? status;
  final PriceBandSourceType sourceType;
  final String? storePriceRuleId;
  final List<PriceBandValidationWarningDto> warnings;
  final ReadinessSummaryDto readinessSummary;
}
