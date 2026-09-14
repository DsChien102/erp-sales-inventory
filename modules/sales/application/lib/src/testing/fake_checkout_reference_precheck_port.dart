import '../sales_order/ports/i_checkout_reference_precheck_port.dart';
import '../sales_order/shared/checkout_blocker_codes.dart';
import '../shared/checkout_line_input.dart';
import '../shared/checkout_monetary_summary_dto.dart';
import '../shared/money_dto.dart';
import '../shared/sales_blocker_dto.dart';

final class FakeCheckoutReferencePrecheckPort implements ICheckoutReferencePrecheckPort {
  const FakeCheckoutReferencePrecheckPort({
    this.pricingSummary,
    this.blockers = const <SalesBlockerDto>[],
  });

  factory FakeCheckoutReferencePrecheckPort.productUnavailable() {
    return const FakeCheckoutReferencePrecheckPort(
      blockers: <SalesBlockerDto>[
        SalesBlockerDto(
          code: CheckoutBlockerCodes.productNotSellable,
          message: 'Product is no longer sellable.',
          field: 'lines[0]',
        ),
      ],
    );
  }

  factory FakeCheckoutReferencePrecheckPort.inventoryUnavailable() {
    return const FakeCheckoutReferencePrecheckPort(
      blockers: <SalesBlockerDto>[
        SalesBlockerDto(
          code: CheckoutBlockerCodes.inventoryUnavailable,
          message: 'Inventory is not available for checkout.',
          field: 'lines[0]',
        ),
      ],
    );
  }

  factory FakeCheckoutReferencePrecheckPort.dependencyUnavailable() {
    return const FakeCheckoutReferencePrecheckPort(
      blockers: <SalesBlockerDto>[
        SalesBlockerDto(
          code: CheckoutBlockerCodes.dependencyUnavailable,
          message: 'Checkout dependency is temporarily unavailable.',
        ),
      ],
    );
  }

  final CheckoutMonetarySummaryDto? pricingSummary;
  final List<SalesBlockerDto> blockers;

  @override
  Future<CheckoutReferencePrecheckDecision> precheck({
    required String storeId,
    String? customerId,
    required String currencyCode,
    required List<CheckoutLineInput> lines,
    int? expectedSourceVersion,
  }) async {
    return CheckoutReferencePrecheckDecision(
      lines: lines,
      pricingSummary: pricingSummary ?? _summaryFromLines(lines, currencyCode),
      blockers: blockers,
    );
  }

  CheckoutMonetarySummaryDto _summaryFromLines(
    List<CheckoutLineInput> lines,
    String currencyCode,
  ) {
    var totalMinor = 0;
    for (final line in lines) {
      final unitPrice = line.unitPrice;
      if (unitPrice == null) continue;
      totalMinor += unitPrice.amountMinor * line.quantity.quantityMicros ~/ 1000000;
    }
    final total = MoneyDto(amountMinor: totalMinor, currencyCode: currencyCode);
    return CheckoutMonetarySummaryDto(
      subtotal: total,
      discountTotal: MoneyDto(amountMinor: 0, currencyCode: currencyCode),
      grandTotal: total,
    );
  }
}
