import '../../models/sales_order_draft/sales_compose_line_vm.dart';
import '../../models/shared/sales_pricing_models.dart';
import 'sales_compose_state.dart';

typedef SalesConfirmFn = Future<bool> Function();

sealed class SalesManualPriceResult {
  const SalesManualPriceResult();
}

final class SalesManualPriceApplied extends SalesManualPriceResult {
  const SalesManualPriceApplied({
    required this.acceptedDraft,
    required this.savedPrivatePrice,
  });

  final SalesManualPriceDraft acceptedDraft;
  final bool savedPrivatePrice;
}

final class SalesManualPriceCancelled extends SalesManualPriceResult {
  const SalesManualPriceCancelled();
}

final class SalesManualPriceFailed extends SalesManualPriceResult {
  const SalesManualPriceFailed({required this.message});

  final String message;
}

typedef SalesManualPriceApplyFn = Future<SalesManualPriceResult> Function({
  required SalesComposeState state,
  required SalesComposeLineVm line,
  required SalesManualPriceDraft draft,
  required SalesConfirmFn confirmBelowFloor,
  required SalesConfirmFn confirmOverwrite,
});
