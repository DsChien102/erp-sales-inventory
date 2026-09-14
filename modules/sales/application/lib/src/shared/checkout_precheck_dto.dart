import 'checkout_monetary_summary_dto.dart';
import 'receivable_requirement_dto.dart';
import 'sales_blocker_dto.dart';

final class CheckoutPrecheckDto {
  CheckoutPrecheckDto({
    required this.canFinalize,
    required List<SalesBlockerDto> blockers,
    required this.monetarySummary,
    required this.receivableRequirement,
  }) : blockers = List.unmodifiable(blockers);

  final bool canFinalize;
  final List<SalesBlockerDto> blockers;
  final CheckoutMonetarySummaryDto monetarySummary;
  final ReceivableRequirementDto receivableRequirement;
}
