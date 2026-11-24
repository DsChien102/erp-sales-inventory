final class SalesPricingLineInput {
  const SalesPricingLineInput({
    required this.localLineId,
    required this.productId,
    required this.productUnitId,
    required this.quantityMicros,
    this.manualUnitPriceMinor,
    this.manualDiscountMinor,
    this.manualDiscountBasisPoints,
  });

  final String localLineId;
  final String productId;
  final String productUnitId;
  final int quantityMicros;
  final int? manualUnitPriceMinor;
  final int? manualDiscountMinor;
  final int? manualDiscountBasisPoints;

  int get manualIntentCount => [
    manualUnitPriceMinor,
    manualDiscountMinor,
    manualDiscountBasisPoints,
  ].where((value) => value != null).length;
}

final class SalesPricingLinePreviewDto {
  const SalesPricingLinePreviewDto({
    required this.localLineId,
    required this.appliedUnitPriceMinor,
    required this.discountMinor,
    required this.lineTotalMinor,
    required this.sourceCode,
    required this.listPriceMinor,
    required this.floorPriceMinor,
    required this.warningCodes,
    required this.blockingCodes,
  });

  final String localLineId;
  final int appliedUnitPriceMinor;
  final int discountMinor;
  final int lineTotalMinor;
  final String sourceCode;
  final int? listPriceMinor;
  final int? floorPriceMinor;
  final List<String> warningCodes;
  final List<String> blockingCodes;
}

final class SalesWorkingStatePricingPreviewDto {
  const SalesWorkingStatePricingPreviewDto({
    required this.contextVersion,
    required this.previewToken,
    required this.currencyCode,
    required this.lines,
  });

  final int contextVersion;
  final String previewToken;
  final String currencyCode;
  final List<SalesPricingLinePreviewDto> lines;
}

final class SalesManualPriceEvaluationDto {
  const SalesManualPriceEvaluationDto({
    required this.allowed,
    required this.requiresAcknowledgement,
    required this.normalizedUnitPriceMinor,
    required this.floorPriceMinor,
    required this.canViewFloor,
    required this.warningCodes,
    required this.blockingCode,
    required this.message,
  });

  final bool allowed;
  final bool requiresAcknowledgement;
  final int normalizedUnitPriceMinor;
  final int? floorPriceMinor;
  final bool canViewFloor;
  final List<String> warningCodes;
  final String? blockingCode;
  final String? message;
}

