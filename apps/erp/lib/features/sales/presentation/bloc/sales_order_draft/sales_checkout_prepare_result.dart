import '../../models/sales_order/sales_checkout_draft_args.dart';
import 'sales_compose_state.dart';

sealed class SalesCheckoutPrepareResult {
  const SalesCheckoutPrepareResult();
}

final class SalesCheckoutPrepareReady extends SalesCheckoutPrepareResult {
  const SalesCheckoutPrepareReady(this.args);

  final SalesCheckoutDraftArgs args;
}

final class SalesCheckoutPrepareBlocked extends SalesCheckoutPrepareResult {
  const SalesCheckoutPrepareBlocked({required this.message});

  final String message;
}

final class SalesCheckoutPrepareFailed extends SalesCheckoutPrepareResult {
  const SalesCheckoutPrepareFailed({required this.message});

  final String message;
}

typedef SalesCheckoutPrepareFn =
    Future<SalesCheckoutPrepareResult> Function(SalesComposeState state);
