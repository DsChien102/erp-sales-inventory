import '../sales_order/ports/i_pricing_preview_port.dart';
import '../shared/checkout_monetary_summary_dto.dart';
import '../shared/draft_line_preview_dto.dart';
import '../shared/money_dto.dart';
import '../shared/pricing_preview_dto.dart';
import '../shared/product_snapshot_dto.dart';
import '../shared/product_unit_snapshot_dto.dart';
import '../shared/quantity_dto.dart';
import '../shared/sales_blocker_dto.dart';
import '../shared/sales_order_working_state_dto.dart';

final class FakePricingPreviewPort implements IPricingPreviewPort {
  FakePricingPreviewPort({
    this.unitPriceMinor = 100000,
    this.failPreview = false,
  });

  final int unitPriceMinor;
  final bool failPreview;

  @override
  Future<PricingPreviewDto> previewWorkingState({
    required String tenantId,
    required SalesOrderWorkingStateDto workingState,
  }) async {
    final currency = workingState.currencyCode;
    if (failPreview) {
      return PricingPreviewDto(
        lines: const <DraftLinePreviewDto>[],
        summary: CheckoutMonetarySummaryDto(
          subtotal: MoneyDto(amountMinor: 0, currencyCode: currency),
          discountTotal: MoneyDto(amountMinor: 0, currencyCode: currency),
          grandTotal: MoneyDto(amountMinor: 0, currencyCode: currency),
        ),
        blockers: const <SalesBlockerDto>[
          SalesBlockerDto(code: 'REFERENCE_UNAVAILABLE', message: 'Pricing unavailable.'),
        ],
      );
    }
    final lines = workingState.lines.map((line) {
      final unitPrice =
          line.unitPrice ?? MoneyDto(amountMinor: unitPriceMinor, currencyCode: currency);
      final gross = unitPrice.amountMinor * line.quantity.quantityMicros ~/ QuantityDto.scale;
      return DraftLinePreviewDto(
        product: ProductSnapshotDto(
          productId: line.productId,
          sku: null,
          displayName: line.productId,
        ),
        unit: ProductUnitSnapshotDto(
          productUnitId: line.productUnitId,
          unitCode: null,
          unitName: line.productUnitId,
        ),
        quantity: line.quantity,
        unitPrice: unitPrice,
        lineTotal: MoneyDto(amountMinor: gross, currencyCode: currency),
      );
    }).toList(growable: false);
    final subtotal = lines.fold<int>(0, (sum, line) => sum + line.lineTotal.amountMinor);
    return PricingPreviewDto(
      lines: lines,
      summary: CheckoutMonetarySummaryDto(
        subtotal: MoneyDto(amountMinor: subtotal, currencyCode: currency),
        discountTotal: MoneyDto(amountMinor: 0, currencyCode: currency),
        grandTotal: MoneyDto(amountMinor: subtotal, currencyCode: currency),
      ),
      blockers: const <SalesBlockerDto>[],
    );
  }
}
