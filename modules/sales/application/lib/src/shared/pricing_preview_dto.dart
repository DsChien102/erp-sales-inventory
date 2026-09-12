import 'checkout_monetary_summary_dto.dart';
import 'draft_line_preview_dto.dart';
import 'sales_blocker_dto.dart';

final class PricingPreviewDto {
  PricingPreviewDto({
    required List<DraftLinePreviewDto> lines,
    required this.summary,
    required List<SalesBlockerDto> blockers,
  }) : lines = List.unmodifiable(lines),
       blockers = List.unmodifiable(blockers);

  final List<DraftLinePreviewDto> lines;
  final CheckoutMonetarySummaryDto summary;
  final List<SalesBlockerDto> blockers;
}
