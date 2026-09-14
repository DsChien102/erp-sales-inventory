import 'package:erp/features/sales/presentation.dart';

SalesManualPriceRequest buildSalesManualPriceRequest({
  required SalesComposeState state,
  required SalesComposeLineVm line,
  required SalesManualPriceDraft draft,
  required bool acknowledgeBelowFloor,
}) => SalesManualPriceRequest(
  customerId: state.customer.partnerId,
  productId: line.identity.productId,
  productUnitId: line.identity.productUnitId,
  quantityMicros: line.input.quantity * 1000000,
  currencyCode: draft.acceptedUnitPrice.currencyCode,
  contextVersion: state.pricingContextVersion,
  manualUnitPriceMinor: draft.manualUnitPriceMinor,
  manualDiscountMinor: draft.manualDiscountMinor,
  manualDiscountBasisPoints: draft.manualDiscountBasisPoints,
  acknowledgeBelowFloor: acknowledgeBelowFloor,
);

SalesPrivatePriceSaveRequest buildSalesPrivatePriceSaveRequest({
  required SalesComposeState state,
  required SalesComposeLineVm line,
  required SalesManualPriceDraft draft,
  required bool acknowledgeFloorWarning,
  required bool confirmOverwrite,
}) => SalesPrivatePriceSaveRequest(
  composeSessionId: state.draftId,
  sourceLineId: line.identity.lineId,
  manualIntentRevision: state.pricingContextVersion + 1,
  customerId: state.customer.partnerId,
  productId: line.identity.productId,
  productUnitId: line.identity.productUnitId,
  acceptedUnitPrice: draft.acceptedUnitPrice,
  currencyCode: draft.acceptedUnitPrice.currencyCode,
  effectiveFrom: DateTime.now().toUtc(),
  contextVersion: state.pricingContextVersion,
  acknowledgeFloorWarning: acknowledgeFloorWarning,
  confirmOverwrite: confirmOverwrite,
);
