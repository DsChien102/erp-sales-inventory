import 'package:vet45_sales_application/application.dart';

/// Deferred Catalog/Inventory adapter until owner ports are wired.
///
/// Exchange unit prices are a client preview from `preview_return_exchange_pricing`.
/// The server prices the line itself and compares that preview. Product, unit,
/// and stock lookups stay on this adapter.
final class UnavailableReturnExchangeReferencePort implements IReturnExchangeReferencePort {
  @override
  Future<ReturnExchangeReferenceDecision> evaluate({
    required String tenantId,
    required String actorId,
    required String salesOrderId,
    required List<ReturnExchangeLineInput> lines,
    required bool reserveExchangeStock,
  }) async {
    final exchangeLines = lines.where((line) => line.kind == ReturnExchangeLineKind.exchangeLine);
    final now = DateTime.now().toUtc();
    return ReturnExchangeReferenceDecision(
      blockers: const <SalesBlockerDto>[],
      exchangePricingByProductUnitId: <String, PricingSnapshotDto>{
        for (final line in exchangeLines)
          line.productUnitId: PricingSnapshotDto(
            unitPrice:
                line.exchangeUnitPrice ?? const MoneyDto(amountMinor: 0, currencyCode: 'VND'),
            source: 'client_preview',
            pricedAt: now,
          ),
      },
      exchangeProductsByProductUnitId: <String, ProductSnapshotDto>{
        for (final line in exchangeLines)
          line.productUnitId:
              line.exchangeProductSnapshot ??
              ProductSnapshotDto(
                productId: line.productId,
                sku: null,
                displayName: line.productId,
              ),
      },
      exchangeUnitsByProductUnitId: <String, ProductUnitSnapshotDto>{
        for (final line in exchangeLines)
          line.productUnitId:
              line.exchangeUnitSnapshot ??
              ProductUnitSnapshotDto(
                productUnitId: line.productUnitId,
                unitCode: null,
                unitName: line.productUnitId,
              ),
      },
      reservationIds: const <String>[],
    );
  }

  @override
  Future<void> releaseReservations({
    required String tenantId,
    required String returnExchangeId,
    required List<String> reservationIds,
    required String idempotencyKey,
  }) async {
    return;
  }
}
