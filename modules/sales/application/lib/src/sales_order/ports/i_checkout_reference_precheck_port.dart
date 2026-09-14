import '../../shared/checkout_line_input.dart';
import '../../shared/checkout_monetary_summary_dto.dart';
import '../../shared/sales_blocker_dto.dart';

final class CheckoutReferencePrecheckDecision {
  CheckoutReferencePrecheckDecision({
    required List<CheckoutLineInput> lines,
    required this.pricingSummary,
    required List<SalesBlockerDto> blockers,
  }) : lines = List.unmodifiable(lines),
       blockers = List.unmodifiable(blockers);

  final List<CheckoutLineInput> lines;
  final CheckoutMonetarySummaryDto pricingSummary;
  final List<SalesBlockerDto> blockers;
}

abstract interface class ICheckoutReferencePrecheckPort {
  Future<CheckoutReferencePrecheckDecision> precheck({
    required String storeId,
    String? customerId,
    required String currencyCode,
    required List<CheckoutLineInput> lines,
    int? expectedSourceVersion,
  });
}
