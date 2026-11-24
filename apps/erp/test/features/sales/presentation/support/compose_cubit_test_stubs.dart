import 'package:erp/features/sales/presentation/lookups/sales_pricing_ports.dart';
import 'package:erp/features/sales/presentation.dart';

Future<SalesCheckoutPrepareResult> composeTestNoopPrepareCheckout(
  SalesComposeState state,
) async {
  throw StateError('must not checkout');
}

Future<SalesManualPriceResult> composeTestNoopApplyManualPrice({
  required SalesComposeState state,
  required SalesComposeLineVm line,
  required SalesManualPriceDraft draft,
  required SalesConfirmFn confirmBelowFloor,
  required SalesConfirmFn confirmOverwrite,
}) async {
  throw StateError('must not adjust price');
}

SalesComposeCubit composeTestCubit({
  required String draftId,
  SalesPricingPreviewFn? previewPricing,
  SalesDraftPersistFn? persistDraft,
  SalesDraftRestoreFn? restoreDraft,
  SalesCheckoutPrepareFn? prepareCheckout,
  SalesManualPriceApplyFn? applyManualPriceFlow,
  Duration quantityPricingDebounceDuration = const Duration(milliseconds: 300),
  String? composeSessionId,
}) {
  return SalesComposeCubit(
    draftId: draftId,
    previewPricing: previewPricing ?? (_) => throw StateError('must not call preview'),
    persistDraft: persistDraft ?? (_) => throw StateError('must not persist'),
    restoreDraft: restoreDraft ?? (_) => throw StateError('must not restore'),
    prepareCheckout: prepareCheckout ?? composeTestNoopPrepareCheckout,
    applyManualPriceFlow: applyManualPriceFlow ?? composeTestNoopApplyManualPrice,
    quantityPricingDebounceDuration: quantityPricingDebounceDuration,
    composeSessionId: composeSessionId,
  );
}
