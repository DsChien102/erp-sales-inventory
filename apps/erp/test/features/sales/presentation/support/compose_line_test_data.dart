import 'package:erp/features/sales/data/models.dart';
import 'package:erp/features/sales/presentation.dart';

MoneyDto composeTestMoney(int amountMinor, {String currencyCode = 'VND'}) =>
    MoneyDto(amountMinor: amountMinor, currencyCode: currencyCode);

/// Builds a compose line for unit/widget tests via [.composed].
SalesComposeLineVm composeTestLine({
  required String lineId,
  required String productId,
  String productUnitId = 'unit-1',
  String productName = 'Product',
  String unitLabel = 'Hộp',
  required int quantity,
  required MoneyDto baseUnitPrice,
  required MoneyDto appliedUnitPrice,
  int? stockQuantity,
  MoneyDto? listUnitPrice,
  MoneyDto? floorUnitPrice,
  int? manualUnitPriceMinor,
  int? manualDiscountMinor,
  int? manualDiscountBasisPoints,
  String? pricingSourceCode,
  MoneyDto? pricedLineTotal,
  int? pricedLineTotalMinor,
  MoneyDto? pricedUnitDiscount,
  int? pricedUnitDiscountMinor,
  List<String> pricingBlockingCodes = const [],
  List<String> pricingWarningCodes = const [],
  int pricedContextVersion = -1,
}) {
  final resolvedPricedLineTotal = pricedLineTotal ??
      (pricedLineTotalMinor == null
          ? null
          : composeTestMoney(pricedLineTotalMinor, currencyCode: appliedUnitPrice.currencyCode));
  final resolvedPricedUnitDiscount = pricedUnitDiscount ??
      (pricedUnitDiscountMinor == null
          ? null
          : composeTestMoney(pricedUnitDiscountMinor, currencyCode: appliedUnitPrice.currencyCode));

  final pricing = pricedContextVersion >= 0 && resolvedPricedLineTotal != null
      ? ComposeLinePricingReady(
          contextVersion: pricedContextVersion,
          amounts: ComposePricedAmounts(
            listUnitPrice: listUnitPrice ?? baseUnitPrice,
            appliedUnitPrice: appliedUnitPrice,
            unitDiscount: resolvedPricedUnitDiscount ??
                MoneyDto(amountMinor: 0, currencyCode: appliedUnitPrice.currencyCode),
            lineTotal: resolvedPricedLineTotal,
            floorUnitPrice: floorUnitPrice,
          ),
          meta: ComposePricingMeta(
            sourceCode: pricingSourceCode,
            blockingCodes: pricingBlockingCodes,
            warningCodes: pricingWarningCodes,
          ),
        )
      : ComposeLinePricingNotReady(
          provisionalAppliedUnitPrice: appliedUnitPrice,
          provisionalListUnitPrice: listUnitPrice,
          provisionalFloorUnitPrice: floorUnitPrice,
        );

  return SalesComposeLineVm.composed(
    identity: ComposeLineIdentity(
      lineId: lineId,
      productId: productId,
      productUnitId: productUnitId,
      productName: productName,
      unitLabel: unitLabel,
      catalogUnitPrice: baseUnitPrice,
    ),
    input: ComposeLineUserInput(
      quantity: quantity,
      manual: ComposeManualPricing(
        unitPriceMinor: manualUnitPriceMinor,
        discountMinor: manualDiscountMinor,
        discountBasisPoints: manualDiscountBasisPoints,
      ),
    ),
    pricing: pricing,
    stock: stockQuantity == null
        ? null
        : ComposeLineStockHint(availableQuantity: stockQuantity),
  );
}
