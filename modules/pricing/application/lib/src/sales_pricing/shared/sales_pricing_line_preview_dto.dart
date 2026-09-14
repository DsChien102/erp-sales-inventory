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
