import 'sales_pricing_line_preview_dto.dart';

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
