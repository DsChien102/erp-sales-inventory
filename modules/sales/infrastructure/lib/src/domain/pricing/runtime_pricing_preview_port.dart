import 'package:vet45_sales_application/application.dart';

/// Runtime pricing-preview adapter used until the authoritative Theme-4 Pricing
/// preview integration is promoted (E2E blocker). Computes a local preview from
/// the frozen working-state DTO (unit prices already on lines when present).
final class RuntimePricingPreviewPort implements IPricingPreviewPort {
  const RuntimePricingPreviewPort();

  @override
  Future<PricingPreviewDto> previewWorkingState({
    required String tenantId,
    required SalesOrderWorkingStateDto workingState,
  }) async {
    final currency = workingState.currencyCode;
    final linePreviews = <DraftLinePreviewDto>[
      for (final line in workingState.lines) _linePreview(line, currency),
    ];
    final subtotal = linePreviews.fold<int>(
      0,
      (sum, line) => sum + line.lineTotal.amountMinor,
    );
    return PricingPreviewDto(
      lines: linePreviews,
      summary: CheckoutMonetarySummaryDto(
        subtotal: MoneyDto(amountMinor: subtotal, currencyCode: currency),
        discountTotal: MoneyDto(amountMinor: 0, currencyCode: currency),
        grandTotal: MoneyDto(amountMinor: subtotal, currencyCode: currency),
      ),
      blockers: const <SalesBlockerDto>[],
    );
  }

  static DraftLinePreviewDto _linePreview(CheckoutLineInput line, String currencyCode) {
    final unitPrice =
        line.unitPrice ?? MoneyDto(amountMinor: 0, currencyCode: currencyCode);
    final lineTotal =
        unitPrice.amountMinor * line.quantity.quantityMicros ~/ QuantityDto.scale;
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
      lineTotal: MoneyDto(
        amountMinor: lineTotal < 0 ? 0 : lineTotal,
        currencyCode: unitPrice.currencyCode,
      ),
    );
  }
}
